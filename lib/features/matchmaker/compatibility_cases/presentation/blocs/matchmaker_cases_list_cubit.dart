import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/state/paginated_list_state.dart';

import '../../../shared/domain/entities/compatibility_case_update.dart';
import '../../../shared/domain/entities/matchmaker_realtime_status.dart';
import '../../../shared/domain/ports/matchmaker_realtime_port.dart';
import '../../domain/entities/case_formal_request.dart';
import '../../domain/entities/compatibility_case.dart';
import '../../domain/entities/formal_request_status.dart';
import '../../domain/entities/matchmaker_cases_filter.dart';
import '../../domain/usecases/get_compatibility_cases_usecase.dart';

/// Owns the single paginated compatibility-cases list. Pagination,
/// refresh and load-more bookkeeping come from [PaginatedListCubitMixin];
/// this class wires the fetch (throw-on-failure) AND the matchmaker
/// realtime port:
///   • `CompatibilityCaseUpdated` → update a row in place, including terminal
///     states so completed/ended filters keep working.
///   • realtime reconnect → re-fetch page 1 to catch up on anything missed
///     while the socket was down (SignalR does not replay missed events).
///
/// The shell's `IndexedStack` keeps this cubit alive across tab switches,
/// so live updates apply even while the matchmaker is on another tab. The
/// connection itself is owned by the shell, never by this cubit.
class MatchmakerCasesListCubit
    extends Cubit<PaginatedListState<CompatibilityCase>>
    with SafeEmit<PaginatedListState<CompatibilityCase>> {
  final GetCompatibilityCasesUseCase _getCases;
  final MatchmakerRealtimePort _realtimePort;

  StreamSubscription<CompatibilityCaseUpdate>? _caseUpdatesSub;
  StreamSubscription<MatchmakerRealtimeStatus>? _statusSub;
  bool _hasBeenConnected;
  MatchmakerCasesFilter _filter = const MatchmakerCasesFilter();
  int _requestGeneration = 0;

  MatchmakerCasesListCubit({
    required GetCompatibilityCasesUseCase getCases,
    required MatchmakerRealtimePort realtimePort,
  }) : _getCases = getCases,
       _realtimePort = realtimePort,
       _hasBeenConnected =
           realtimePort.status == MatchmakerRealtimeStatus.connected,
       super(const PaginatedListState()) {
    _caseUpdatesSub = _realtimePort.caseUpdates.listen(_onCaseUpdate);
    _statusSub = _realtimePort.statusStream.listen(_onStatus);
  }

  static const int pageSize = 20;

  MatchmakerCasesFilter get filter => _filter;

  /// Replaces the server query, drops every loaded page and fetches page 1.
  /// The generation guard prevents a late response for the old query from
  /// repopulating the list after the filter changed.
  Future<void> applyFilter(MatchmakerCasesFilter filter) async {
    if (_filter == filter) return;
    _filter = filter;
    _requestGeneration++;
    emit(const PaginatedListState<CompatibilityCase>());
    await loadFirst();
  }

  Future<void> loadFirst() async {
    if (state.isLoading) return;
    final generation = ++_requestGeneration;
    final filter = _filter;
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await _getCases(page: 1, pageSize: pageSize, filter: filter);
    if (isClosed || generation != _requestGeneration) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (page) => emit(
        state.copyWith(
          items: page.items,
          page: 1,
          hasMore: page.hasMore,
          isLoading: false,
          clearError: true,
          totalCount: page.totalCount,
          clearTotalCount: page.totalCount == null,
        ),
      ),
    );
  }

  Future<void> refresh() async {
    if (state.isLoading || state.isRefreshing) return;
    final generation = ++_requestGeneration;
    final filter = _filter;
    emit(state.copyWith(isRefreshing: true, clearError: true));
    final result = await _getCases(page: 1, pageSize: pageSize, filter: filter);
    if (isClosed || generation != _requestGeneration) return;
    result.fold(
      (failure) => emit(
        state.copyWith(isRefreshing: false, errorMessage: failure.message),
      ),
      (page) => emit(
        state.copyWith(
          items: page.items,
          page: 1,
          hasMore: page.hasMore,
          isRefreshing: false,
          clearError: true,
          totalCount: page.totalCount,
          clearTotalCount: page.totalCount == null,
        ),
      ),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isRefreshing || state.isLoadingMore) return;
    if (!state.hasMore) return;
    final generation = _requestGeneration;
    final filter = _filter;
    final nextPage = state.page + 1;
    emit(state.copyWith(isLoadingMore: true, clearError: true));
    final result = await _getCases(
      page: nextPage,
      pageSize: pageSize,
      filter: filter,
    );
    if (isClosed || generation != _requestGeneration) return;
    result.fold(
      (failure) => emit(
        state.copyWith(isLoadingMore: false, errorMessage: failure.message),
      ),
      (page) => emit(
        state.copyWith(
          items: [...state.items, ...page.items],
          page: page.pageNumber,
          hasMore: page.hasMore,
          isLoadingMore: false,
          clearError: true,
          // The total belongs to the query, not the page — re-read it on every
          // page so a set that grew or shrank mid-scroll stays truthful. Items
          // accumulate here; totalCount does NOT.
          totalCount: page.totalCount,
          clearTotalCount: page.totalCount == null,
        ),
      ),
    );
  }

  /// Apply a live `CompatibilityCaseUpdated` by replacing its formal-request
  /// status in place. Terminal rows stay loaded so completed/ended filters do
  /// not lose them immediately after an update. Unknown caseId is ignored.
  void _onCaseUpdate(CompatibilityCaseUpdate update) {
    applyStatusUpdate(
      caseId: update.caseId,
      formalRequestId: update.formalRequestId,
      status: FormalRequestStatus.fromString(update.newStatus),
    );
  }

  /// Applies a confirmed status locally. This is used by both SignalR and the
  /// mutation success path, so a completed row survives even if the realtime
  /// event arrives late or the following list endpoint omits terminal rows.
  void applyStatusUpdate({
    required int caseId,
    required int formalRequestId,
    required FormalRequestStatus status,
  }) {
    if (isClosed) return;
    final index = state.items.indexWhere((c) => c.caseId == caseId);
    if (index < 0) return;
    final existing = state.items[index];
    final formalRequest =
        (existing.formalRequest ??
                CaseFormalRequest(id: formalRequestId, status: status))
            .copyWith(status: status);
    emit(
      state.copyWith(
        items: [...state.items]
          ..[index] = existing.copyWith(formalRequest: formalRequest),
      ),
    );
    AppLogger.info(
      'MATCHMAKER — case $caseId status → $status (in place)',
      tag: 'MM-RT',
    );
  }

  /// If the mutation endpoint rejects a stale list permission, stop offering
  /// the same action until a later server refresh says it is available again.
  void markStatusUpdateUnavailable(int caseId) {
    if (isClosed) return;
    final index = state.items.indexWhere((c) => c.caseId == caseId);
    if (index < 0 || !state.items[index].canUpdateFormalRequestStatus) return;
    emit(
      state.copyWith(
        items: [...state.items]
          ..[index] = state.items[index].copyWith(
            canUpdateFormalRequestStatus: false,
          ),
      ),
    );
  }

  /// Reflect a note save/delete from the note sheet on the card's indicator
  /// in place — no list reload (same single-row replace as [_onCaseUpdate]).
  /// Unknown / off-page caseId, or no actual change, is a no-op.
  void markNoteState(int caseId, bool hasNote) {
    if (isClosed) return;
    final index = state.items.indexWhere((c) => c.caseId == caseId);
    if (index < 0 || state.items[index].hasMyNote == hasNote) return;
    emit(
      state.copyWith(
        items: [...state.items]
          ..[index] = state.items[index].copyWith(hasMyNote: hasNote),
      ),
    );
  }

  /// Catch-up: on re-entry into `connected` after a prior connection
  /// (reconnect / resume-from-background), re-fetch page 1 — SignalR does
  /// NOT replay events missed while the socket was down. The first-ever
  /// connect never triggers this (the tab's initial `loadFirst` covers it).
  void _onStatus(MatchmakerRealtimeStatus status) {
    if (isClosed) return;
    final shouldCatchUp =
        _hasBeenConnected && status == MatchmakerRealtimeStatus.connected;
    if (status == MatchmakerRealtimeStatus.connected) {
      _hasBeenConnected = true;
    }
    if (shouldCatchUp) refresh();
  }

  @override
  Future<void> close() async {
    await _caseUpdatesSub?.cancel();
    _caseUpdatesSub = null;
    await _statusSub?.cancel();
    _statusSub = null;
    // NOTE: the realtime connection is owned by the matchmaker shell
    // (app-wide), not by this screen-scoped cubit — so we cancel our
    // subscriptions but never disconnect the port here.
    await super.close();
  }
}
