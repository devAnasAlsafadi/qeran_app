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
  // Photo-exchange request (initiator, stage 0)
  photoExchangeRequestSuccess,
  photoExchangeRequestAlreadyPending,
  photoExchangeRequestLikeNotAccepted,
  photoExchangeRequestRequiresSubscription,
  photoExchangeRequestLimitReached,
  photoExchangeRequestFailure,
  photoExchangeRequestUnderReview,
  // Photo-exchange accept/reject (responder, stage 0)
  photoExchangeAcceptSuccess,
  photoExchangeRejectSuccess,
  photoExchangeRespondNotFound,
  photoExchangeRespondExpired,
  photoExchangeRespondFailure,
  // Stage-0 inquiry — share partner card + predefined message
  // Formal step (stage 1/2) — POST /api/formal-step/request/{likeRequestId}
  formalStepSuccess,
  formalStepAlreadyPending,
  formalStepNotAllowed,
  formalStepCaseEnded,
  formalStepUnderReview,
  formalStepFailure,
  // Formal-step accept/reject (responder) — keyed by pendingFormalStep.id
  formalStepAcceptSuccess,
  formalStepRejectSuccess,
  formalStepRespondNotFound,
  formalStepRespondExpired,
  formalStepRespondCaseEnded,
  formalStepRespondFailure,
  // Cancel — ending the whole case, at any stage. Keyed by likeRequestId,
  // because it acts on the CASE rather than on a request inside it.
  cancelSuccess,
  cancelAlreadyEnded,
  cancelNotFound,
  cancelFailure,
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

  /// LIKE-REQUEST ids whose `photo-exchange/request/{likeRequestId}`
  /// call is in-flight (Matches tab, stage 0, initiator path). Keyed
  /// by `likeRequestId`.
  final Set<int> photoExchangeRequestInFlightLikeIds;

  /// PHOTO-EXCHANGE REQUEST ids whose `accept`/`reject` call is in-
  /// flight (Matches tab, stage 0, responder path). Keyed by
  /// `pendingPhotoExchange.id`. Two separate id namespaces.
  final Set<int> photoExchangeAcceptInFlightRequestIds;
  final Set<int> photoExchangeRejectInFlightRequestIds;

  /// FORMAL-STEP request ids being answered. Keyed by `pendingFormalStep.id`
  /// like the photo-exchange pair above, NOT by the like id the request set
  /// below uses — the two live side by side and index different things.
  final Set<int> formalStepAcceptInFlightRequestIds;
  final Set<int> formalStepRejectInFlightRequestIds;

  /// LIKE-REQUEST ids whose case is being cancelled.
  ///
  /// Keyed by the LIKE id, not a request id, and that is the whole distinction
  /// from the two sets above: accept and reject answer one formal-step request
  /// inside a case, while this ends the case they live in. A card can only
  /// ever have one cancel in flight, so no accept/reject-style pair.
  final Set<int> cancelInFlightLikeIds;

  /// LIKE-REQUEST ids whose formal-step request is in-flight (stage 1/2).
  ///
  /// There is no `formalStepSent` twin. Whether the step was requested is a
  /// server fact now — `MatchCard.hasRequestedFormalStep` reads it off the
  /// row — where the set this replaced lost the answer on every restart.
  final Set<int> formalStepInFlightLikeIds;

  /// Which match card has its compatibility journey open, if any. At most
  /// one at a time.
  ///
  /// View state, and here for the same reason [activeTab] is: `loadMatches`
  /// emits `loading` before it fetches, so the matches list is torn down and
  /// rebuilt on every pull-to-refresh and every time the gallery sheet closes.
  /// Held in the list widget it would collapse itself on all of those.
  final int? openJourneyLikeRequestId;

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
    this.photoExchangeRequestInFlightLikeIds = const <int>{},
    this.photoExchangeAcceptInFlightRequestIds = const <int>{},
    this.photoExchangeRejectInFlightRequestIds = const <int>{},
    this.formalStepAcceptInFlightRequestIds = const <int>{},
    this.formalStepRejectInFlightRequestIds = const <int>{},
    this.formalStepInFlightLikeIds = const <int>{},
    this.cancelInFlightLikeIds = const <int>{},
    this.openJourneyLikeRequestId,
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

  bool isPhotoExchangeRequesting(int likeRequestId) =>
      photoExchangeRequestInFlightLikeIds.contains(likeRequestId);

  bool isPhotoExchangeAccepting(int requestId) =>
      photoExchangeAcceptInFlightRequestIds.contains(requestId);

  bool isPhotoExchangeRejecting(int requestId) =>
      photoExchangeRejectInFlightRequestIds.contains(requestId);

  bool isPhotoExchangeResponding(int requestId) =>
      isPhotoExchangeAccepting(requestId) ||
      isPhotoExchangeRejecting(requestId);



  bool isFormalStepSending(int likeRequestId) =>
      formalStepInFlightLikeIds.contains(likeRequestId);

  bool isFormalStepAccepting(int requestId) =>
      formalStepAcceptInFlightRequestIds.contains(requestId);

  bool isFormalStepRejecting(int requestId) =>
      formalStepRejectInFlightRequestIds.contains(requestId);

  /// Either answer in flight. Both buttons retire together — answering twice
  /// from one card is never what was meant.
  bool isFormalStepResponding(int requestId) =>
      isFormalStepAccepting(requestId) || isFormalStepRejecting(requestId);

  bool isCancelling(int likeRequestId) =>
      cancelInFlightLikeIds.contains(likeRequestId);

  bool isJourneyOpen(int likeRequestId) =>
      openJourneyLikeRequestId == likeRequestId;

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
    Set<int>? photoExchangeRequestInFlightLikeIds,
    Set<int>? photoExchangeAcceptInFlightRequestIds,
    Set<int>? photoExchangeRejectInFlightRequestIds,
    Set<int>? formalStepAcceptInFlightRequestIds,
    Set<int>? formalStepRejectInFlightRequestIds,
    Set<int>? formalStepInFlightLikeIds,
    Set<int>? cancelInFlightLikeIds,
    int? openJourneyLikeRequestId,
    bool clearOpenJourney = false,
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
      photoExchangeRequestInFlightLikeIds:
          photoExchangeRequestInFlightLikeIds ??
          this.photoExchangeRequestInFlightLikeIds,
      photoExchangeAcceptInFlightRequestIds:
          photoExchangeAcceptInFlightRequestIds ??
          this.photoExchangeAcceptInFlightRequestIds,
      photoExchangeRejectInFlightRequestIds:
          photoExchangeRejectInFlightRequestIds ??
          this.photoExchangeRejectInFlightRequestIds,
      formalStepAcceptInFlightRequestIds:
          formalStepAcceptInFlightRequestIds ??
          this.formalStepAcceptInFlightRequestIds,
      formalStepRejectInFlightRequestIds:
          formalStepRejectInFlightRequestIds ??
          this.formalStepRejectInFlightRequestIds,
      formalStepInFlightLikeIds:
          formalStepInFlightLikeIds ?? this.formalStepInFlightLikeIds,
      cancelInFlightLikeIds:
          cancelInFlightLikeIds ?? this.cancelInFlightLikeIds,
      openJourneyLikeRequestId: clearOpenJourney
          ? null
          : (openJourneyLikeRequestId ?? this.openJourneyLikeRequestId),
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
    photoExchangeRequestInFlightLikeIds,
    photoExchangeAcceptInFlightRequestIds,
    photoExchangeRejectInFlightRequestIds,
    formalStepAcceptInFlightRequestIds,
    formalStepRejectInFlightRequestIds,
    formalStepInFlightLikeIds,
    cancelInFlightLikeIds,
    openJourneyLikeRequestId,
    actionEvent,
    actionEventVersion,
  ];
}
