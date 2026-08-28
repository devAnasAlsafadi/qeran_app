import '../../domain/entities/formal_step_outcome.dart';
import '../../domain/entities/like_action_outcome.dart';
import '../../domain/entities/photo_exchange_outcome.dart';
import 'likes_state.dart';
import 'match_actions_state.dart';

/// Turns each use case's OUTCOME into the one-shot event the screen renders
/// as a snackbar.
///
/// Two enums, because two cubits: the like pair answers with
/// [LikesActionEvent], the five match families with [MatchActionEvent]. They
/// stay in ONE file anyway — a mapper belongs beside the others it is easy to
/// confuse with, and which cubit executes it is not the axis that matters
/// when you are checking that a decline is not reported as an approval.
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

MatchActionEvent photoExchangeRequestEvent(PhotoExchangeRequestOutcome outcome) {
  return switch (outcome) {
    PhotoExchangeRequestSuccess() =>
      MatchActionEvent.photoRequestSuccess,
    PhotoExchangeRequestAlreadyPending() =>
      MatchActionEvent.photoRequestAlreadyPending,
    PhotoExchangeRequestLikeNotAccepted() =>
      MatchActionEvent.photoRequestLikeNotAccepted,
    PhotoExchangeRequestRequiresSubscription() =>
      MatchActionEvent.photoRequestRequiresSubscription,
    PhotoExchangeRequestLimitReached() =>
      MatchActionEvent.photoRequestLimitReached,
    PhotoExchangeRequestProfileUnderReview() =>
      MatchActionEvent.photoRequestUnderReview,
    PhotoExchangeRequestFailure() =>
      MatchActionEvent.photoRequestFailure,
  };
}

MatchActionEvent photoExchangeRespondEvent(
  PhotoExchangeRespondOutcome outcome, {
  required bool isAccept,
}) {
  return switch (outcome) {
    PhotoExchangeRespondSuccess() =>
      isAccept
          ? MatchActionEvent.photoAcceptSuccess
          : MatchActionEvent.photoRejectSuccess,
    PhotoExchangeRespondNotFound() =>
      MatchActionEvent.photoRespondNotFound,
    PhotoExchangeRespondExpired() =>
      MatchActionEvent.photoRespondExpired,
    PhotoExchangeRespondFailure() =>
      MatchActionEvent.photoRespondFailure,
  };
}

MatchActionEvent formalStepRequestEvent(FormalStepRequestOutcome outcome) {
  return switch (outcome) {
    FormalStepRequestSuccess() => MatchActionEvent.formalStepSuccess,
    FormalStepRequestAlreadyPending() =>
      MatchActionEvent.formalStepAlreadyPending,
    FormalStepRequestNotAllowed() => MatchActionEvent.formalStepNotAllowed,
    FormalStepRequestCaseEnded() => MatchActionEvent.formalStepCaseEnded,
    FormalStepRequestProfileUnderReview() =>
      MatchActionEvent.formalStepUnderReview,
    FormalStepRequestFailure() => MatchActionEvent.formalStepFailure,
  };
}

MatchActionEvent formalStepRespondEvent(
  FormalStepRespondOutcome outcome, {
  required bool isAccept,
}) {
  return switch (outcome) {
    FormalStepRespondSuccess() => isAccept
        ? MatchActionEvent.formalStepAcceptSuccess
        : MatchActionEvent.formalStepRejectSuccess,
    FormalStepRespondNotFound() =>
      MatchActionEvent.formalStepRespondNotFound,
    FormalStepRespondExpired() => MatchActionEvent.formalStepRespondExpired,
    FormalStepRespondCaseEnded() =>
      MatchActionEvent.formalStepRespondCaseEnded,
    FormalStepRespondFailure() => MatchActionEvent.formalStepRespondFailure,
  };
}

MatchActionEvent caseCancelEvent(CaseCancelOutcome outcome) {
  return switch (outcome) {
    CaseCancelSuccess() => MatchActionEvent.cancelSuccess,
    CaseCancelAlreadyEnded() => MatchActionEvent.cancelAlreadyEnded,
    CaseCancelNotFound() => MatchActionEvent.cancelNotFound,
    CaseCancelFailure() => MatchActionEvent.cancelFailure,
  };
}
