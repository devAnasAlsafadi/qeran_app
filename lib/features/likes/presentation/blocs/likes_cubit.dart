import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';

import 'package:qeran/core/app_logger.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';

import '../../domain/entities/likes_tab.dart';
import '../../domain/usecases/accept_like_usecase.dart';
import '../../domain/usecases/get_incoming_likes_usecase.dart';
import '../../domain/usecases/get_matches_usecase.dart';
import '../../domain/usecases/get_outgoing_likes_usecase.dart';
import '../../domain/usecases/reject_like_usecase.dart';
import 'likes_action_events.dart';
import 'likes_refetch_rules.dart';
import 'likes_state.dart';

/// Screen-scoped controller for the Likes / Interests tabs (Sent /
/// Received / Matches).
///
/// Each tab is an independent async slot in [LikesState]; switching is
/// instant once a tab has loaded, and one tab can be in `failure` while
/// the others are in `loaded`. Tabs load lazily — their loader fires
/// the first time the user activates the tab, then the result is
/// cached until pull-to-refresh.
///
/// **Cross-tab freshness**: when a Received-tab `acceptLike` succeeds,
/// the matches slot is invalidated back to `initial` so the next visit
/// refetches and the new Stage-0 match shows up.
class LikesCubit extends Cubit<LikesState> with SafeEmit<LikesState> {
  final GetIncomingLikesUseCase _getIncoming;
  final GetOutgoingLikesUseCase _getOutgoing;
  final AcceptLikeUseCase _acceptLike;
  final RejectLikeUseCase _rejectLike;
  final GetMatchesUseCase _getMatches;
  final ProfileGateCubit _profileGate;

  LikesCubit({
    required GetIncomingLikesUseCase getIncoming,
    required GetOutgoingLikesUseCase getOutgoing,
    required AcceptLikeUseCase acceptLike,
    required RejectLikeUseCase rejectLike,
    required GetMatchesUseCase getMatches,
    required ProfileGateCubit profileGate,
  }) : _getIncoming = getIncoming,
       _getOutgoing = getOutgoing,
       _acceptLike = acceptLike,
       _rejectLike = rejectLike,
       _getMatches = getMatches,
       _profileGate = profileGate,
       super(const LikesState());

  /// Kicks off the active tab if it hasn't loaded yet. Called once
  /// when the screen mounts so the user sees data without an extra tap.
  void primeActiveTab() {
    switch (state.activeTab) {
      case LikesTab.sent:
        if (state.outgoingStatus == LikesAsyncStatus.initial) loadOutgoing();
      case LikesTab.received:
        if (state.incomingStatus == LikesAsyncStatus.initial) loadIncoming();
      case LikesTab.matches:
        if (state.matchesStatus == LikesAsyncStatus.initial) loadMatches();
    }
  }

  void switchTab(LikesTab tab) {
    if (state.activeTab == tab) return;
    emit(state.copyWith(activeTab: tab));
    // Lazy-load the tab the user just opened, the first time only.
    switch (tab) {
      case LikesTab.sent:
        if (state.outgoingStatus == LikesAsyncStatus.initial) loadOutgoing();
      case LikesTab.received:
        if (state.incomingStatus == LikesAsyncStatus.initial) loadIncoming();
      case LikesTab.matches:
        if (state.matchesStatus == LikesAsyncStatus.initial) loadMatches();
    }
  }

  Future<void> loadIncoming() async {
    emit(
      state.copyWith(
        incomingStatus: LikesAsyncStatus.loading,
        clearIncomingError: true,
      ),
    );
    final result = await _getIncoming();
    if (isClosed) return;
    result.fold(
      (failure) {
        // The raw `failure.message` is whatever the data source / HTTP
        // layer threw — possibly a raw English token like "Operation
        // Failed". We log it for engineering follow-up but never push
        // it through `.tr()`; the UI uses localized generic copy.
        AppLogger.warning(
          'Incoming likes failed — raw="${failure.message}"',
          tag: 'LIKES',
        );
        emit(
          state.copyWith(
            incomingStatus: LikesAsyncStatus.failure,
            incomingErrorKey: failure.message,
          ),
        );
      },
      (data) => emit(
        state.copyWith(
          incomingStatus: LikesAsyncStatus.loaded,
          incoming: data,
          clearIncomingError: true,
        ),
      ),
    );
  }

  Future<void> loadOutgoing() async {
    emit(
      state.copyWith(
        outgoingStatus: LikesAsyncStatus.loading,
        clearOutgoingError: true,
      ),
    );
    final result = await _getOutgoing();
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'Outgoing likes failed — raw="${failure.message}"',
          tag: 'LIKES',
        );
        emit(
          state.copyWith(
            outgoingStatus: LikesAsyncStatus.failure,
            outgoingErrorKey: failure.message,
          ),
        );
      },
      (data) => emit(
        state.copyWith(
          outgoingStatus: LikesAsyncStatus.loaded,
          outgoing: data,
          clearOutgoingError: true,
        ),
      ),
    );
  }

  Future<void> loadMatches() async {
    emit(
      state.copyWith(
        matchesStatus: LikesAsyncStatus.loading,
        clearMatchesError: true,
      ),
    );
    final result = await _getMatches();
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'Matches failed — raw="${failure.message}"',
          tag: 'MATCHES',
        );
        emit(
          state.copyWith(
            matchesStatus: LikesAsyncStatus.failure,
            matchesErrorKey: failure.message,
          ),
        );
      },
      (data) => emit(
        state.copyWith(
          matchesStatus: LikesAsyncStatus.loaded,
          matches: data,
          clearMatchesError: true,
        ),
      ),
    );
  }

  /// Pull-to-refresh entry for the active tab. Always forces a fetch.
  Future<void> refresh() {
    switch (state.activeTab) {
      case LikesTab.sent:
        return loadOutgoing();
      case LikesTab.received:
        return loadIncoming();
      case LikesTab.matches:
        return loadMatches();
    }
  }

  // ── Like accept / reject ────────────────────────────────────────────

  Future<void> acceptLike(int likeRequestId) async {
    if (state.isActionInFlight(likeRequestId)) return;
    // Approval pre-gate — an unapproved user can't accept likes yet.
    if (_profileGate.isGated) {
      emit(
        state.copyWith(
          actionEvent: LikesActionEvent.acceptUnderReview,
          actionEventVersion: state.actionEventVersion + 1,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        acceptInFlightIds: {...state.acceptInFlightIds, likeRequestId},
      ),
    );
    final result = await _acceptLike(likeRequestId);
    if (isClosed) return;
    final LikesActionEvent event = result.fold((failure) {
      AppLogger.warning(
        'LIKES — accept transport failure id=$likeRequestId '
        'raw="${failure.message}"',
        tag: 'LIKES',
      );
      return LikesActionEvent.acceptFailure;
    }, acceptLikeEvent);
    final clearedAccept = {...state.acceptInFlightIds}..remove(likeRequestId);
    // On accept success the matches list will get a new Stage-0 row —
    // invalidate the matches slot so the next tab visit refetches.
    final invalidateMatches = event == LikesActionEvent.acceptSuccess;
    emit(
      state.copyWith(
        acceptInFlightIds: clearedAccept,
        actionEvent: event,
        actionEventVersion: state.actionEventVersion + 1,
        resetMatchesToInitial: invalidateMatches,
      ),
    );
    if (refetchIncomingAfterLikeAction(event)) {
      await loadIncoming();
    }
  }

  Future<void> rejectLike(int likeRequestId) async {
    if (state.isActionInFlight(likeRequestId)) return;
    emit(
      state.copyWith(
        rejectInFlightIds: {...state.rejectInFlightIds, likeRequestId},
      ),
    );
    final result = await _rejectLike(likeRequestId);
    if (isClosed) return;
    final LikesActionEvent event = result.fold((failure) {
      AppLogger.warning(
        'LIKES — reject transport failure id=$likeRequestId '
        'raw="${failure.message}"',
        tag: 'LIKES',
      );
      return LikesActionEvent.rejectFailure;
    }, rejectLikeEvent);
    final clearedReject = {...state.rejectInFlightIds}..remove(likeRequestId);
    emit(
      state.copyWith(
        rejectInFlightIds: clearedReject,
        actionEvent: event,
        actionEventVersion: state.actionEventVersion + 1,
      ),
    );
    if (refetchIncomingAfterLikeAction(event)) {
      await loadIncoming();
    }
  }

  // ── Photo exchange — initiator (request) ───────────────────────────

  // ── Photo exchange — responder (accept / reject) ───────────────────

  // ── Compatibility journey ──

  // ── Matchmaker inquiry / formal step — profile card + text message ──

}
