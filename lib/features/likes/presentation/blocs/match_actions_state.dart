import 'package:equatable/equatable.dart';

/// One-shot outcomes of an action taken ON a match card, listened to by the
/// screen for snackbars and the paywall sheet. [MatchActionsState.eventVersion]
/// is bumped every time one is published, so the listener reacts to version
/// changes and a transient toast never fires twice for one tap.
///
/// Its own enum, split out of `LikesActionEvent` with the cubit. The ten
/// like accept/reject members stayed behind: they belong to the Received tab
/// and this cubit cannot emit them. Keeping one shared enum would leave each
/// listener answering events it can never see, and exhaustiveness is only
/// worth having while every arm is one that could actually arrive.
enum MatchActionEvent {
  none,
  // Photo-exchange request (initiator, stage 0)
  photoRequestSuccess,
  photoRequestAlreadyPending,
  photoRequestLikeNotAccepted,
  photoRequestRequiresSubscription,
  photoRequestLimitReached,
  photoRequestFailure,
  photoRequestUnderReview,
  // Photo-exchange accept/reject (responder, stage 0)
  photoAcceptSuccess,
  photoRejectSuccess,
  photoRespondNotFound,
  photoRespondExpired,
  photoRespondFailure,
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

/// What is currently in flight against the match cards, plus the one-shot
/// outcome of the last action.
///
/// Holds no match DATA. The list itself belongs to `LikesState`, which owns
/// all three tabs' payloads — this cubit acts on cards and never reads them,
/// which is what let the two separate at all.
///
/// ⚠️ Two id namespaces live side by side here and index different things.
/// The sets named `...LikeIds` are keyed by `likeRequestId`, the card's id.
/// The sets named `...RequestIds` are keyed by the id of a request INSIDE
/// that case — `pendingPhotoExchange.id` or `pendingFormalStep.id`. Both are
/// ints, so a mix-up compiles and reaches a real endpoint with a real id.
class MatchActionsState extends Equatable {
  const MatchActionsState({
    this.photoRequestInFlightLikeIds = const <int>{},
    this.photoAcceptInFlightRequestIds = const <int>{},
    this.photoRejectInFlightRequestIds = const <int>{},
    this.formalStepInFlightLikeIds = const <int>{},
    this.formalStepAcceptInFlightRequestIds = const <int>{},
    this.formalStepRejectInFlightRequestIds = const <int>{},
    this.cancelInFlightLikeIds = const <int>{},
    this.openJourneyLikeRequestId,
    this.event = MatchActionEvent.none,
    this.eventVersion = 0,
  });

  /// LIKE-REQUEST ids whose `photo-exchange/request/{likeRequestId}` call is
  /// in flight (stage 0, initiator path).
  final Set<int> photoRequestInFlightLikeIds;

  /// PHOTO-EXCHANGE REQUEST ids whose accept/reject is in flight (stage 0,
  /// responder path). Keyed by `pendingPhotoExchange.id`.
  final Set<int> photoAcceptInFlightRequestIds;
  final Set<int> photoRejectInFlightRequestIds;

  /// LIKE-REQUEST ids whose formal-step request is in flight (stage 1/2).
  ///
  /// There is no `formalStepSent` twin. Whether the step was requested is a
  /// server fact — `MatchCard.hasRequestedFormalStep` reads it off the row —
  /// where the set this replaced lost the answer on every restart.
  final Set<int> formalStepInFlightLikeIds;

  /// FORMAL-STEP request ids being answered. Keyed by `pendingFormalStep.id`,
  /// NOT by the like id the request set above uses.
  final Set<int> formalStepAcceptInFlightRequestIds;
  final Set<int> formalStepRejectInFlightRequestIds;

  /// LIKE-REQUEST ids whose case is being cancelled. Keyed by the LIKE id,
  /// because cancel ends the case the other requests live inside. A card can
  /// only ever have one cancel in flight, so no accept/reject-style pair.
  final Set<int> cancelInFlightLikeIds;

  /// Which match card has its compatibility journey open, if any. At most one
  /// at a time.
  ///
  /// View state, and here rather than in the list widget because
  /// `loadMatches` emits `loading` before it fetches: the list is torn down
  /// and rebuilt on every pull-to-refresh and every time the gallery sheet
  /// closes, and an open journey held in the widget would collapse on all of
  /// them.
  final int? openJourneyLikeRequestId;

  /// The screen reacts on every [eventVersion] bump and ignores
  /// [MatchActionEvent.none].
  final MatchActionEvent event;
  final int eventVersion;

  bool isPhotoRequesting(int likeRequestId) =>
      photoRequestInFlightLikeIds.contains(likeRequestId);

  bool isPhotoAccepting(int requestId) =>
      photoAcceptInFlightRequestIds.contains(requestId);

  bool isPhotoRejecting(int requestId) =>
      photoRejectInFlightRequestIds.contains(requestId);

  /// Either photo answer in flight. Both buttons retire together.
  bool isPhotoResponding(int requestId) =>
      isPhotoAccepting(requestId) || isPhotoRejecting(requestId);

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

  MatchActionsState copyWith({
    Set<int>? photoRequestInFlightLikeIds,
    Set<int>? photoAcceptInFlightRequestIds,
    Set<int>? photoRejectInFlightRequestIds,
    Set<int>? formalStepInFlightLikeIds,
    Set<int>? formalStepAcceptInFlightRequestIds,
    Set<int>? formalStepRejectInFlightRequestIds,
    Set<int>? cancelInFlightLikeIds,
    int? openJourneyLikeRequestId,
    bool clearOpenJourney = false,
    MatchActionEvent? event,
    int? eventVersion,
  }) {
    return MatchActionsState(
      photoRequestInFlightLikeIds:
          photoRequestInFlightLikeIds ?? this.photoRequestInFlightLikeIds,
      photoAcceptInFlightRequestIds:
          photoAcceptInFlightRequestIds ?? this.photoAcceptInFlightRequestIds,
      photoRejectInFlightRequestIds:
          photoRejectInFlightRequestIds ?? this.photoRejectInFlightRequestIds,
      formalStepInFlightLikeIds:
          formalStepInFlightLikeIds ?? this.formalStepInFlightLikeIds,
      formalStepAcceptInFlightRequestIds:
          formalStepAcceptInFlightRequestIds ??
          this.formalStepAcceptInFlightRequestIds,
      formalStepRejectInFlightRequestIds:
          formalStepRejectInFlightRequestIds ??
          this.formalStepRejectInFlightRequestIds,
      cancelInFlightLikeIds:
          cancelInFlightLikeIds ?? this.cancelInFlightLikeIds,
      openJourneyLikeRequestId: clearOpenJourney
          ? null
          : (openJourneyLikeRequestId ?? this.openJourneyLikeRequestId),
      event: event ?? this.event,
      eventVersion: eventVersion ?? this.eventVersion,
    );
  }

  @override
  List<Object?> get props => [
    photoRequestInFlightLikeIds,
    photoAcceptInFlightRequestIds,
    photoRejectInFlightRequestIds,
    formalStepInFlightLikeIds,
    formalStepAcceptInFlightRequestIds,
    formalStepRejectInFlightRequestIds,
    cancelInFlightLikeIds,
    openJourneyLikeRequestId,
    event,
    eventVersion,
  ];
}
