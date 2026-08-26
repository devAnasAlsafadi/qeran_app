// Typed outcomes for formal-step domain calls.
//
// Same contract as `PhotoExchangeRequestOutcome`: these live on the `Right`
// of an `Either`, transport and unmapped failures stay on the `Left` as
// `Failure`, and raw server messages are kept for logging only — the UI
// speaks in localized keys.

/// Outcome of `POST /api/formal-step/request/{likeRequestId}`.
///
/// SIX members where the photo-exchange twin has seven, and the missing one
/// is deliberate: the formal step is not subscription-gated. Neither
/// `SUBSCRIPTION_REQUIRED` nor a limit code appears in the server's list for
/// this endpoint, so there is no paywall branch and no upgrade sheet to open.
sealed class FormalStepRequestOutcome {
  const FormalStepRequestOutcome();
}

/// The server recorded the request and both members now carry a
/// `pendingFormalStep` block.
final class FormalStepRequestSuccess extends FormalStepRequestOutcome {
  /// The new `pendingFormalStep.id`, when the envelope carries one. The
  /// contract does not document `data` for this endpoint, so it is read
  /// defensively and nothing depends on it — the matches refresh brings the
  /// real block back either way.
  final int? requestId;
  final String serverMessage;
  const FormalStepRequestSuccess({
    required this.requestId,
    required this.serverMessage,
  });
}

/// `FORMAL_STEP_ALREADY_PENDING` — a request is open on this match. Either
/// this member sent one, or the other did while this screen was stale; the UI
/// refreshes so whichever it is surfaces on the card.
final class FormalStepRequestAlreadyPending extends FormalStepRequestOutcome {
  final String serverMessage;
  const FormalStepRequestAlreadyPending({required this.serverMessage});
}

/// `FORMAL_STEP_NOT_ALLOWED` or `LIKE_NOT_ACCEPTED` — the couple is not at a
/// point where the formal step can be asked for: photos are not through, the
/// like was never accepted, or the step has already been answered once.
///
/// The two codes share a member because they share an answer. Splitting them
/// would buy two strings that say the same thing to a member who cannot act
/// on the difference.
final class FormalStepRequestNotAllowed extends FormalStepRequestOutcome {
  final String serverMessage;
  const FormalStepRequestNotAllowed({required this.serverMessage});
}

/// `CASE_NOT_ACTIVE` — the compatibility case was cancelled, failed or
/// completed. Nothing further is accepted on it.
final class FormalStepRequestCaseEnded extends FormalStepRequestOutcome {
  final String serverMessage;
  const FormalStepRequestCaseEnded({required this.serverMessage});
}

/// `PROFILE_NOT_APPROVED` — the caller's profile is back under review. Shows
/// the same "under review" message the photo-exchange path uses, NOT a
/// subscription gate.
final class FormalStepRequestProfileUnderReview
    extends FormalStepRequestOutcome {
  final String serverMessage;
  const FormalStepRequestProfileUnderReview({required this.serverMessage});
}

/// `CASE_NOT_FOUND`, `UNAUTHORIZED`, `VALIDATION_ERROR`, and any status-0
/// envelope this build does not recognise.
final class FormalStepRequestFailure extends FormalStepRequestOutcome {
  final String serverMessage;
  final String? errorCode;
  const FormalStepRequestFailure({
    required this.serverMessage,
    required this.errorCode,
  });
}
