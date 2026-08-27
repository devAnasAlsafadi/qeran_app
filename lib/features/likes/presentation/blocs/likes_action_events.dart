import '../../domain/entities/formal_step_outcome.dart';
import '../../domain/entities/like_action_outcome.dart';
import '../../domain/entities/photo_exchange_outcome.dart';
import 'likes_state.dart';

/// Turns each use case's OUTCOME into the one-shot [LikesActionEvent] the
/// screen renders as a snackbar.
///
/// Pure, and lifted out of the cubit for that reason — none of them reads
/// state, emits, or touches a use case. Seven families of server answer, seven
/// functions, each exhaustive over its own sealed family so a new member is a
/// compile error rather than a silently unhandled case.
///
/// The families stay separate on purpose. Several look near-identical — the
/// two respond mappers differ only in which events they name — but folding
/// them would mean one refusal being classified for two different actions, and
/// a decline reported as an approval is the kind of thing that reads fine in
/// review.

LikesActionEvent acceptLikeEvent(LikeActionOutcome outcome) {
  return switch (outcome) {
    LikeActionSuccess() => LikesActionEvent.acceptSuccess,
    LikeActionRequiresSubscription() =>
      LikesActionEvent.acceptRequiresSubscription,
    LikeActionExpired() => LikesActionEvent.acceptExpired,
    LikeActionNotFoundOrExpired() => LikesActionEvent.acceptNotFound,
    LikeActionProfileUnderReview() => LikesActionEvent.acceptUnderReview,
    LikeActionFailure() => LikesActionEvent.acceptFailure,
  };
}

LikesActionEvent rejectLikeEvent(LikeActionOutcome outcome) {
  return switch (outcome) {
    LikeActionSuccess() => LikesActionEvent.rejectSuccess,
    // Reject is never subscription-gated server-side; treat it as
    // generic failure rather than opening the paywall.
    LikeActionRequiresSubscription() => LikesActionEvent.rejectFailure,
    LikeActionExpired() => LikesActionEvent.rejectExpired,
    LikeActionNotFoundOrExpired() => LikesActionEvent.rejectNotFound,
    // Reject is never approval-gated server-side; treat an under-review
    // result as a generic failure rather than surfacing "under review".
    LikeActionProfileUnderReview() => LikesActionEvent.rejectFailure,
    LikeActionFailure() => LikesActionEvent.rejectFailure,
  };
}

LikesActionEvent photoExchangeRequestEvent(PhotoExchangeRequestOutcome outcome) {
  return switch (outcome) {
    PhotoExchangeRequestSuccess() =>
      LikesActionEvent.photoExchangeRequestSuccess,
    PhotoExchangeRequestAlreadyPending() =>
      LikesActionEvent.photoExchangeRequestAlreadyPending,
    PhotoExchangeRequestLikeNotAccepted() =>
      LikesActionEvent.photoExchangeRequestLikeNotAccepted,
    PhotoExchangeRequestRequiresSubscription() =>
      LikesActionEvent.photoExchangeRequestRequiresSubscription,
    PhotoExchangeRequestLimitReached() =>
      LikesActionEvent.photoExchangeRequestLimitReached,
    PhotoExchangeRequestProfileUnderReview() =>
      LikesActionEvent.photoExchangeRequestUnderReview,
    PhotoExchangeRequestFailure() =>
      LikesActionEvent.photoExchangeRequestFailure,
  };
}

LikesActionEvent photoExchangeRespondEvent(
  PhotoExchangeRespondOutcome outcome, {
  required bool isAccept,
}) {
  return switch (outcome) {
    PhotoExchangeRespondSuccess() =>
      isAccept
          ? LikesActionEvent.photoExchangeAcceptSuccess
          : LikesActionEvent.photoExchangeRejectSuccess,
    PhotoExchangeRespondNotFound() =>
      LikesActionEvent.photoExchangeRespondNotFound,
    PhotoExchangeRespondExpired() =>
      LikesActionEvent.photoExchangeRespondExpired,
    PhotoExchangeRespondFailure() =>
      LikesActionEvent.photoExchangeRespondFailure,
  };
}

LikesActionEvent formalStepRequestEvent(FormalStepRequestOutcome outcome) {
  return switch (outcome) {
    FormalStepRequestSuccess() => LikesActionEvent.formalStepSuccess,
    FormalStepRequestAlreadyPending() =>
      LikesActionEvent.formalStepAlreadyPending,
    FormalStepRequestNotAllowed() => LikesActionEvent.formalStepNotAllowed,
    FormalStepRequestCaseEnded() => LikesActionEvent.formalStepCaseEnded,
    FormalStepRequestProfileUnderReview() =>
      LikesActionEvent.formalStepUnderReview,
    FormalStepRequestFailure() => LikesActionEvent.formalStepFailure,
  };
}

LikesActionEvent formalStepRespondEvent(
  FormalStepRespondOutcome outcome, {
  required bool isAccept,
}) {
  return switch (outcome) {
    FormalStepRespondSuccess() => isAccept
        ? LikesActionEvent.formalStepAcceptSuccess
        : LikesActionEvent.formalStepRejectSuccess,
    FormalStepRespondNotFound() =>
      LikesActionEvent.formalStepRespondNotFound,
    FormalStepRespondExpired() => LikesActionEvent.formalStepRespondExpired,
    FormalStepRespondCaseEnded() =>
      LikesActionEvent.formalStepRespondCaseEnded,
    FormalStepRespondFailure() => LikesActionEvent.formalStepRespondFailure,
  };
}

LikesActionEvent caseCancelEvent(CaseCancelOutcome outcome) {
  return switch (outcome) {
    CaseCancelSuccess() => LikesActionEvent.cancelSuccess,
    CaseCancelAlreadyEnded() => LikesActionEvent.cancelAlreadyEnded,
    CaseCancelNotFound() => LikesActionEvent.cancelNotFound,
    CaseCancelFailure() => LikesActionEvent.cancelFailure,
  };
}
