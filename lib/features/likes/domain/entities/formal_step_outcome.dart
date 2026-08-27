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

/// Outcome of `POST /api/formal-step/{requestId}/accept` and `/reject`.
///
/// FIVE members where the photo-exchange twin has four. The extra one is
/// [FormalStepRespondCaseEnded]: a compatibility case can be called off from
/// either side while a formal step sits open, and answering a request on a
/// case that no longer exists is a different thing to tell someone than
/// "that request is gone".
///
/// Accept and reject share the family. They fail in exactly the same ways —
/// the request has to be found, live, and on a running case either way — and
/// which one was pressed is already known at the call site.
sealed class FormalStepRespondOutcome {
  const FormalStepRespondOutcome();
}

/// The answer was recorded. On accept the server creates the `FormalRequest`
/// and moves the case to `AwaitingMatchmakerCoordination`; on reject it moves
/// to `FormalStepRejected`. Either way the matches refresh is what brings the
/// new shape back — nothing here carries it.
final class FormalStepRespondSuccess extends FormalStepRespondOutcome {
  final String serverMessage;
  const FormalStepRespondSuccess({required this.serverMessage});
}

/// `FORMAL_STEP_NOT_FOUND` — no open request with that id.
///
/// ⚠️ The server also answers this to a member who is not the responder, so
/// it CANNOT be read as "the request was withdrawn". It is deliberately
/// ambiguous: the API never confirms a request exists to someone who has no
/// business acting on it. Copy for this outcome must survive both readings.
final class FormalStepRespondNotFound extends FormalStepRespondOutcome {
  final String serverMessage;
  const FormalStepRespondNotFound({required this.serverMessage});
}

/// `FORMAL_STEP_EXPIRED` — the window closed before the answer arrived.
///
/// Reachable even with a live-looking countdown on screen: the chip ticks
/// against a value fetched minutes ago, and the server sweeps on its own
/// clock.
final class FormalStepRespondExpired extends FormalStepRespondOutcome {
  final String serverMessage;
  const FormalStepRespondExpired({required this.serverMessage});
}

/// `CASE_NOT_ACTIVE` — the case was cancelled, failed or completed while the
/// request sat open, so there is nothing left to answer.
final class FormalStepRespondCaseEnded extends FormalStepRespondOutcome {
  final String serverMessage;
  const FormalStepRespondCaseEnded({required this.serverMessage});
}

/// `UNAUTHORIZED`, `VALIDATION_ERROR`, and any status-0 envelope this build
/// does not recognise.
final class FormalStepRespondFailure extends FormalStepRespondOutcome {
  final String serverMessage;
  final String? errorCode;
  const FormalStepRespondFailure({
    required this.serverMessage,
    required this.errorCode,
  });
}

/// Outcome of `POST /api/matches/{likeRequestId}/cancel`.
///
/// FOUR members, and only one of them is a named refusal. Cancel has no error
/// codes of its own — the backend reuses the shared vocabulary — because there
/// is almost nothing to refuse: it is allowed at every stage for as long as
/// the case is running.
sealed class CaseCancelOutcome {
  const CaseCancelOutcome();
}

/// The case is now `caseStatus = Cancelled`.
///
/// The stage does NOT move — a case cancelled mid-coordination stays at
/// `AwaitingMatchmakerCoordination` and records the ending separately. The row
/// also STAYS in `/api/matches` rather than disappearing, so the refresh
/// brings back a card that still exists and now reads as ended.
final class CaseCancelSuccess extends CaseCancelOutcome {
  final String serverMessage;
  const CaseCancelSuccess({required this.serverMessage});
}

/// `CASE_NOT_ACTIVE` — it had already stopped: cancelled, failed, or the
/// marriage completed. This is what a second cancel gets, and the affordance
/// should already have been hidden, so reaching it means the card was stale.
final class CaseCancelAlreadyEnded extends CaseCancelOutcome {
  final String serverMessage;
  const CaseCancelAlreadyEnded({required this.serverMessage});
}

/// `CASE_NOT_FOUND` — no case on that relationship id.
final class CaseCancelNotFound extends CaseCancelOutcome {
  final String serverMessage;
  const CaseCancelNotFound({required this.serverMessage});
}

/// `UNAUTHORIZED` and anything else this build does not recognise.
final class CaseCancelFailure extends CaseCancelOutcome {
  final String serverMessage;
  final String? errorCode;
  const CaseCancelFailure({
    required this.serverMessage,
    required this.errorCode,
  });
}
