import 'package:equatable/equatable.dart';

import '../../domain/entities/like_requests_data.dart';
import '../../domain/entities/likes_tab.dart';
import '../../domain/entities/match_card.dart';

/// Async status for a single tab's payload.
enum LikesAsyncStatus { initial, loading, loaded, failure }

/// One-shot outcomes the screen listens to for snackbar / paywall side
/// effects. `actionEvent` is bumped via [LikesState.copyWith] every time
/// a new event is published; the screen's `BlocListener` only reacts to
/// version changes so transient toasts never fire twice for one tap.
enum LikesActionEvent {
  none,
  // Like accept/reject (Received tab)
  acceptSuccess,
  acceptRequiresSubscription,
  acceptExpired,
  acceptNotFound,
  acceptFailure,
  acceptUnderReview,
  rejectSuccess,
  rejectExpired,
  rejectNotFound,
  rejectFailure,
}

/// Single state class holding the active tab + per-tab status / data /
/// error. Tabs load lazily and independently — switching is instant once
/// a tab has loaded, and one tab can be in `failure` while the others
/// are in `loaded`.
class LikesState extends Equatable {
  final LikesTab activeTab;

  final LikesAsyncStatus incomingStatus;
  final LikeRequestsData? incoming;
  final String? incomingErrorKey;

  final LikesAsyncStatus outgoingStatus;
  final LikeRequestsData? outgoing;
  final String? outgoingErrorKey;

  final LikesAsyncStatus matchesStatus;
  final List<MatchCard>? matches;
  final String? matchesErrorKey;

  /// Like-request ids whose accept call is in-flight (Received tab).
  final Set<int> acceptInFlightIds;

  /// Like-request ids whose reject call is in-flight (Received tab).
  final Set<int> rejectInFlightIds;

  /// One-shot outcome of the most recent action. The screen reacts on
  /// every [actionEventVersion] bump and ignores [LikesActionEvent.none].
  final LikesActionEvent actionEvent;
  final int actionEventVersion;

  const LikesState({
    this.activeTab = LikesTab.sent,
    this.incomingStatus = LikesAsyncStatus.initial,
    this.incoming,
    this.incomingErrorKey,
    this.outgoingStatus = LikesAsyncStatus.initial,
    this.outgoing,
    this.outgoingErrorKey,
    this.matchesStatus = LikesAsyncStatus.initial,
    this.matches,
    this.matchesErrorKey,
    this.acceptInFlightIds = const <int>{},
    this.rejectInFlightIds = const <int>{},
    this.actionEvent = LikesActionEvent.none,
    this.actionEventVersion = 0,
  });

  bool isActionInFlight(int likeRequestId) =>
      acceptInFlightIds.contains(likeRequestId) ||
      rejectInFlightIds.contains(likeRequestId);

  bool isAccepting(int likeRequestId) =>
      acceptInFlightIds.contains(likeRequestId);

  bool isRejecting(int likeRequestId) =>
      rejectInFlightIds.contains(likeRequestId);

  LikesState copyWith({
    LikesTab? activeTab,
    LikesAsyncStatus? incomingStatus,
    LikeRequestsData? incoming,
    String? incomingErrorKey,
    bool clearIncomingError = false,
    LikesAsyncStatus? outgoingStatus,
    LikeRequestsData? outgoing,
    String? outgoingErrorKey,
    bool clearOutgoingError = false,
    LikesAsyncStatus? matchesStatus,
    List<MatchCard>? matches,
    String? matchesErrorKey,
    bool clearMatchesError = false,
    bool resetMatchesToInitial = false,
    Set<int>? acceptInFlightIds,
    Set<int>? rejectInFlightIds,
    LikesActionEvent? actionEvent,
    int? actionEventVersion,
  }) {
    return LikesState(
      activeTab: activeTab ?? this.activeTab,
      incomingStatus: incomingStatus ?? this.incomingStatus,
      incoming: incoming ?? this.incoming,
      incomingErrorKey: clearIncomingError
          ? null
          : (incomingErrorKey ?? this.incomingErrorKey),
      outgoingStatus: outgoingStatus ?? this.outgoingStatus,
      outgoing: outgoing ?? this.outgoing,
      outgoingErrorKey: clearOutgoingError
          ? null
          : (outgoingErrorKey ?? this.outgoingErrorKey),
      matchesStatus: resetMatchesToInitial
          ? LikesAsyncStatus.initial
          : (matchesStatus ?? this.matchesStatus),
      matches: resetMatchesToInitial ? null : (matches ?? this.matches),
      matchesErrorKey: (resetMatchesToInitial || clearMatchesError)
          ? null
          : (matchesErrorKey ?? this.matchesErrorKey),
      acceptInFlightIds: acceptInFlightIds ?? this.acceptInFlightIds,
      rejectInFlightIds: rejectInFlightIds ?? this.rejectInFlightIds,
      actionEvent: actionEvent ?? this.actionEvent,
      actionEventVersion: actionEventVersion ?? this.actionEventVersion,
    );
  }

  @override
  List<Object?> get props => [
    activeTab,
    incomingStatus,
    incoming,
    incomingErrorKey,
    outgoingStatus,
    outgoing,
    outgoingErrorKey,
    matchesStatus,
    matches,
    matchesErrorKey,
    acceptInFlightIds,
    rejectInFlightIds,
    actionEvent,
    actionEventVersion,
  ];
}
