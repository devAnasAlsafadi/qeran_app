import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/case_stage.dart';
import '../../domain/entities/compatibility_case.dart';

/// Progress of one timeline node relative to the case's current stage.
enum CaseStepState { done, current, future }

/// Colour flavour of the *current* node: a normal in-progress stage, a
/// successful completion, or a non-success ending (rejected / closed /
/// cancelled). Ignored for done / future nodes.
enum CaseStepTone { normal, success, ended }

/// One node of the compatibility-journey timeline (label key + placement).
class CaseTimelineStep {
  const CaseTimelineStep({
    required this.labelKey,
    required this.state,
    required this.tone,
  });

  final String labelKey;
  final CaseStepState state;
  final CaseStepTone tone;
}

/// The five canonical stage labels, indexed by [CaseStage] — the matchmaker's
/// half of the journey the member sees in `match_journey_timeline.dart`. Both
/// sides name the same five nodes with the same five strings.
///
/// ⚠️ These keys are the TIMELINE'S OWN and must stay that way.
///
/// They used to be borrowed — nodes from `stageLabelKey`, `formalStatusLabelKey`
/// and even the status card's «تبادل الصور» field label. That made the rename to
/// the member's vocabulary impossible to do in place: those keys are read as
/// STATUSES elsewhere, where a stage name is the wrong part of speech and
/// throws away the answer. «حالة الطلب الرسمي: التواصل الرسمي مع الأهل»
/// names a stage where the matchmaker needed to read that an appointment is
/// still pending.
///
/// So do not point a node back at a shared key to save a duplicated string.
/// `case_timeline_test.dart` fails if any of the five collides with a status,
/// formal-status or field key.
String caseStageLabelKey(CaseStage stage) => switch (stage) {
      CaseStage.likeAccepted =>
        LocaleKeys.matchmaker_cases_timeline_initial_compatibility,
      CaseStage.photoExchange =>
        LocaleKeys.matchmaker_cases_timeline_photo_exchange,
      CaseStage.waitingAppointment =>
        LocaleKeys.matchmaker_cases_timeline_formal_contact,
      CaseStage.parentsVisited =>
        LocaleKeys.matchmaker_cases_timeline_formal_meeting,
      CaseStage.completed =>
        LocaleKeys.matchmaker_cases_timeline_marriage_completed,
    };

CaseStepTone _toneOf(CaseStageOutcome outcome) => switch (outcome) {
      // A pending formal step is still live — it reads as the current stage in
      // progress, not as an ending.
      CaseStageOutcome.inProgress ||
      CaseStageOutcome.formalStepPending =>
        CaseStepTone.normal,
      CaseStageOutcome.completed => CaseStepTone.success,
      CaseStageOutcome.rejected ||
      CaseStageOutcome.expired ||
      CaseStageOutcome.closed ||
      CaseStageOutcome.cancelled ||
      CaseStageOutcome.formalStepRejected ||
      CaseStageOutcome.formalStepExpired =>
        CaseStepTone.ended,
    };

/// The label that replaces the node's own when the case is not simply moving
/// through it — an off-happy-path terminal, or a step waiting on the other
/// member. Null means the node keeps its canonical label.
///
/// Every outcome names its OWN event. `rejected` / `expired` are the photo
/// exchange; the formal step has its own three. Sharing them would print
/// "رُفض تبادل الصور" over a declined formal step.
String? _overrideLabel(CaseStageOutcome outcome) => switch (outcome) {
      CaseStageOutcome.rejected =>
        LocaleKeys.matchmaker_cases_stage_photo_rejected,
      CaseStageOutcome.expired => LocaleKeys.matchmaker_cases_stage_photo_expired,
      CaseStageOutcome.closed => LocaleKeys.matchmaker_cases_formal_closed,
      CaseStageOutcome.cancelled => LocaleKeys.matchmaker_cases_formal_cancelled,
      CaseStageOutcome.formalStepPending =>
        LocaleKeys.matchmaker_cases_stage_formal_step_pending,
      CaseStageOutcome.formalStepRejected =>
        LocaleKeys.matchmaker_cases_stage_formal_step_rejected,
      CaseStageOutcome.formalStepExpired =>
        LocaleKeys.matchmaker_cases_stage_formal_step_expired,
      CaseStageOutcome.inProgress || CaseStageOutcome.completed => null,
    };

/// Projects a live [CompatibilityCase] onto the canonical timeline. Nodes
/// before the current one are [CaseStepState.done], the current one carries a
/// [CaseStepTone] (normal / success / ended), and later ones are
/// [CaseStepState.future]. Built on the domain [caseStagePlacement] so the
/// filter (08) and the timeline share one projection.
List<CaseTimelineStep> buildCaseTimeline(CompatibilityCase c) {
  final placement = caseStagePlacement(c);
  final index = placement.stage.index;
  final tone = _toneOf(placement.outcome);
  final overrideLabel = _overrideLabel(placement.outcome);

  return [
    for (var i = 0; i < CaseStage.values.length; i++)
      CaseTimelineStep(
        labelKey: (i == index && overrideLabel != null)
            ? overrideLabel
            : caseStageLabelKey(CaseStage.values[i]),
        state: i < index
            ? CaseStepState.done
            : i == index
                ? CaseStepState.current
                : CaseStepState.future,
        tone: i == index ? tone : CaseStepTone.normal,
      ),
  ];
}
