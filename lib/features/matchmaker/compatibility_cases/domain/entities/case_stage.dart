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
enum CaseStageOutcome { inProgress, completed, rejected, expired, closed, cancelled }

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
    // Photos accepted but no formal request yet — the formal track is about to
    // begin; sit at the first formal stage.
    CompatibilityCaseStage.photoExchangeAccepted => const CaseStagePlacement(
        stage: CaseStage.waitingAppointment,
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
    CompatibilityCaseStage.unknown => const CaseStagePlacement(
        stage: CaseStage.likeAccepted,
        outcome: CaseStageOutcome.inProgress,
      ),
  };
}

/// The case's current canonical [CaseStage] — used by the filter (08) to match
/// a case against a selected stage exactly as the timeline places it.
CaseStage caseStageOf(CompatibilityCase c) => caseStagePlacement(c).stage;
