import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/state/paginated_list_cubit_mixin.dart';
import 'package:qeran/core/state/paginated_list_state.dart';

import '../../../shared/domain/entities/compatibility_case_update.dart';
import '../../../shared/domain/entities/matchmaker_realtime_status.dart';
import '../../../shared/domain/ports/matchmaker_realtime_port.dart';
import '../../domain/entities/case_formal_request.dart';
import '../../domain/entities/compatibility_case.dart';
import '../../domain/entities/formal_request_status.dart';
import '../../domain/usecases/get_compatibility_cases_usecase.dart';

/// Owns the single paginated compatibility-cases list. Pagination,
/// refresh and load-more bookkeeping come from [PaginatedListCubitMixin];
/// this class wires the fetch (throw-on-failure) AND the matchmaker
/// realtime port:
///   • `CompatibilityCaseUpdated` → update a row in place, or drop it on
///     a terminal status (the server removes terminal cases from the list).
///   • realtime reconnect → re-fetch page 1 to catch up on anything missed
///     while the socket was down (SignalR does not replay missed events).
///
/// The shell's `IndexedStack` keeps this cubit alive across tab switches,
/// so live updates apply even while the matchmaker is on another tab. The
/// connection itself is owned by the shell, never by this cubit.
class MatchmakerCasesListCubit
    extends Cubit<PaginatedListState<CompatibilityCase>>
    with PaginatedListCubitMixin<CompatibilityCase> {
  final GetCompatibilityCasesUseCase _getCases;
  final MatchmakerRealtimePort _realtimePort;

  StreamSubscription<CompatibilityCaseUpdate>? _caseUpdatesSub;
  StreamSubscription<MatchmakerRealtimeStatus>? _statusSub;
  bool _hasBeenConnected;

  MatchmakerCasesListCubit({
    required GetCompatibilityCasesUseCase getCases,
    required MatchmakerRealtimePort realtimePort,
  })  : _getCases = getCases,
        _realtimePort = realtimePort,
        _hasBeenConnected =
            realtimePort.status == MatchmakerRealtimeStatus.connected,
        super(const PaginatedListState()) {
    _caseUpdatesSub = _realtimePort.caseUpdates.listen(_onCaseUpdate);
    _statusSub = _realtimePort.statusStream.listen(_onStatus);
  }

  @override
  Future<({List<CompatibilityCase> items, bool hasMore})> fetchPage(
    int page,
  ) async {
    final result = await _getCases(page: page, pageSize: pageSize);
    // Throw-on-failure: the mixin captures the (already-localized) message
    // into `errorMessage`. `_CasesFetchException.toString()` returns it.
    return result.fold(
      (failure) => throw _CasesFetchException(failure.message),
      (pageData) => (items: pageData.items, hasMore: pageData.hasMore),
    );
  }

  /// Apply a live `CompatibilityCaseUpdated`: drop the row on a terminal
  /// status (the server drops it from the list), else replace its
  /// formal-request status in place. Unknown caseId (not on a loaded
  /// page) → ignored.
  void _onCaseUpdate(CompatibilityCaseUpdate update) {
    if (isClosed) return;
    final index = state.items.indexWhere((c) => c.caseId == update.caseId);
    if (index < 0) return;
    final status = FormalRequestStatus.fromString(update.newStatus);
    if (status.isTerminal) {
      emit(state.copyWith(items: [...state.items]..removeAt(index)));
      AppLogger.info(
        'MM-RT — case ${update.caseId} terminal ($status) → removed',
        tag: 'MM-RT',
      );
      return;
    }
    final existing = state.items[index];
    final formalRequest = (existing.formalRequest ??
            CaseFormalRequest(id: update.formalRequestId, status: status))
        .copyWith(status: status);
    emit(state.copyWith(
      items: [...state.items]
        ..[index] = existing.copyWith(formalRequest: formalRequest),
    ));
    AppLogger.info(
      'MM-RT — case ${update.caseId} status → $status (in place)',
      tag: 'MM-RT',
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

class _CasesFetchException implements Exception {
  const _CasesFetchException(this.message);
  final String message;
  @override
  String toString() => message;
}
