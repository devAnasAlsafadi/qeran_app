import 'compatibility_case.dart';
import 'compatibility_case_stage.dart';
import 'formal_request_status.dart';

/// The five canonical compatibility-journey stages, in order — the SINGLE
/// source shared by the detail timeline (06) and the cases filter sheet (08),
/// so the filter's stage vocabulary can never diverge from the timeline.
enum CaseStage {
  likeAccepted,
  photoExchange,
  waitingAppointment,
  parentsVisited,
  completed,
}

/// How a case sits on its current stage: still moving forward, completed
/// successfully, or ended off the happy path. Presentation maps this to the
/// timeline node tone + the honest override label; domain keeps it semantic.
///
/// ⚠️ [rejected] and [expired] mean the PHOTO EXCHANGE specifically — their
/// override labels name it. The formal step has its own three members for
/// exactly that reason: reusing [rejected] for a declined formal step made the
/// timeline read "رُفض تبادل الصور", naming the wrong event with full
/// confidence. Any future stage that ends off the happy path needs its own
/// member too, not the nearest-looking one.
enum CaseStageOutcome {
  inProgress,
  completed,
  rejected,
  expired,
  closed,
  cancelled,

  /// The formal step is out and the receiver has not answered. Still moving —
  /// it is simply not the matchmaker's turn.
  formalStepPending,
  formalStepRejected,
  formalStepExpired,
}

/// A case's placement on the canonical journey: which [stage] it currently
/// occupies and the [outcome] there.
class CaseStagePlacement {
  const CaseStagePlacement({required this.stage, required this.outcome});

  final CaseStage stage;
  final CaseStageOutcome outcome;
}

/// Projects a case onto the canonical journey (backend truth): the current
/// stage comes from `formalRequest.status` when a formal request exists,
/// otherwise from the case `stage`. Off-happy-path terminals anchor to the
/// nearest stage — a rejected/expired photo exchange → the photo stage; a
/// closed/cancelled formal request → the first formal stage — with the
/// matching [CaseStageOutcome].
CaseStagePlacement caseStagePlacement(CompatibilityCase c) {
  final formal = c.formalRequest;
  if (formal != null) {
    return switch (formal.status) {
      FormalRequestStatus.waitingForParentAppointment => const CaseStagePlacement(
          stage: CaseStage.waitingAppointment,
          outcome: CaseStageOutcome.inProgress,
        ),
      FormalRequestStatus.parentsVisited => const CaseStagePlacement(
          stage: CaseStage.parentsVisited,
          outcome: CaseStageOutcome.inProgress,
        ),
      FormalRequestStatus.successfullyClosed => const CaseStagePlacement(
          stage: CaseStage.completed,
          outcome: CaseStageOutcome.completed,
        ),
      FormalRequestStatus.compatibilityClosed => const CaseStagePlacement(
          stage: CaseStage.waitingAppointment,
          outcome: CaseStageOutcome.closed,
        ),
      FormalRequestStatus.compatibilityCancelled => const CaseStagePlacement(
          stage: CaseStage.waitingAppointment,
          outcome: CaseStageOutcome.cancelled,
        ),
      FormalRequestStatus.unknown => const CaseStagePlacement(
          stage: CaseStage.waitingAppointment,
          outcome: CaseStageOutcome.inProgress,
        ),
    };
  }
  return switch (c.stage) {
    CompatibilityCaseStage.likeAccepted => const CaseStagePlacement(
        stage: CaseStage.likeAccepted,
        outcome: CaseStageOutcome.inProgress,
      ),
    CompatibilityCaseStage.photoExchangePending => const CaseStagePlacement(
        stage: CaseStage.photoExchange,
        outcome: CaseStageOutcome.inProgress,
      ),
    // Photos are through and nobody has asked for the formal step yet, so the
    // case is still standing on the photo-exchange node. This used to sit at
    // the first FORMAL stage, which was true while the server created a
    // formalRequest the moment photos were exchanged; under the interactive
    // journey a member has to request that step, so claiming the formal track
    // had begun would announce something neither of them has done.
    //
    // The outcome stays inProgress rather than completed even though the
    // exchange itself succeeded: `completed` paints the node with the success
    // tone, and that tone is what the detail screen's no-actions card reads to
    // decide it should say "this case is complete". It is not complete — it is
    // waiting on a member. inProgress makes that card read "awaiting the other
    // party", which is the true statement.
    CompatibilityCaseStage.photoExchangeAccepted => const CaseStagePlacement(
        stage: CaseStage.photoExchange,
        outcome: CaseStageOutcome.inProgress,
      ),
    CompatibilityCaseStage.photoExchangeRejected => const CaseStagePlacement(
        stage: CaseStage.photoExchange,
        outcome: CaseStageOutcome.rejected,
      ),
    CompatibilityCaseStage.photoExchangeExpired => const CaseStagePlacement(
        stage: CaseStage.photoExchange,
        outcome: CaseStageOutcome.expired,
      ),
    // The three formal-step states all sit on the first formal stage: that is
    // the step being negotiated. They keep their own outcomes rather than
    // borrowing the photo ones, so the node says which event it is reporting.
    // Pending in particular must not read as a plain in-progress appointment
    // stage — nothing is waiting on the matchmaker yet.
    CompatibilityCaseStage.formalStepPending => const CaseStagePlacement(
        stage: CaseStage.waitingAppointment,
        outcome: CaseStageOutcome.formalStepPending,
      ),
    CompatibilityCaseStage.formalStepRejected => const CaseStagePlacement(
        stage: CaseStage.waitingAppointment,
        outcome: CaseStageOutcome.formalStepRejected,
      ),
    CompatibilityCaseStage.formalStepExpired => const CaseStagePlacement(
        stage: CaseStage.waitingAppointment,
        outcome: CaseStageOutcome.formalStepExpired,
      ),
    // Approved — the matchmaker is arranging the meeting. Reached through the
    // formalRequest branch above in practice, since the server creates one at
    // this point; mapped here so the projection holds without it.
    CompatibilityCaseStage.awaitingMatchmakerCoordination =>
      const CaseStagePlacement(
        stage: CaseStage.waitingAppointment,
        outcome: CaseStageOutcome.inProgress,
      ),
    CompatibilityCaseStage.parentsVisited => const CaseStagePlacement(
        stage: CaseStage.parentsVisited,
        outcome: CaseStageOutcome.inProgress,
      ),
    CompatibilityCaseStage.marriageCompleted => const CaseStagePlacement(
        stage: CaseStage.completed,
        outcome: CaseStageOutcome.completed,
      ),
    CompatibilityCaseStage.unknown => const CaseStagePlacement(
        stage: CaseStage.likeAccepted,
        outcome: CaseStageOutcome.inProgress,
      ),
  };
}

/// The case's current canonical [CaseStage] — used by the filter (08) to match
/// a case against a selected stage exactly as the timeline places it.
CaseStage caseStageOf(CompatibilityCase c) => caseStagePlacement(c).stage;
