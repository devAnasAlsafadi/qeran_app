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

/// The five canonical stage labels, indexed by [CaseStage]. The SAME keys the
/// status card and the filter sheet (08) use — nodes 0–1 from the case `stage`,
/// nodes 2–4 from `formalRequest.status`, photo-pending/accepted collapsed into
/// one "photo exchange" node.
String caseStageLabelKey(CaseStage stage) => switch (stage) {
      CaseStage.likeAccepted => LocaleKeys.matchmaker_cases_stage_like_accepted,
      CaseStage.photoExchange => LocaleKeys.matchmaker_cases_field_photo_exchange,
      CaseStage.waitingAppointment =>
        LocaleKeys.matchmaker_cases_formal_waiting_appointment,
      CaseStage.parentsVisited =>
        LocaleKeys.matchmaker_cases_formal_parents_visited,
      CaseStage.completed =>
        LocaleKeys.matchmaker_cases_formal_successfully_closed,
    };

CaseStepTone _toneOf(CaseStageOutcome outcome) => switch (outcome) {
      CaseStageOutcome.inProgress => CaseStepTone.normal,
      CaseStageOutcome.completed => CaseStepTone.success,
      CaseStageOutcome.rejected ||
      CaseStageOutcome.expired ||
      CaseStageOutcome.closed ||
      CaseStageOutcome.cancelled =>
        CaseStepTone.ended,
    };

/// The honest override label for an off-happy-path terminal (else null).
String? _overrideLabel(CaseStageOutcome outcome) => switch (outcome) {
      CaseStageOutcome.rejected =>
        LocaleKeys.matchmaker_cases_stage_photo_rejected,
      CaseStageOutcome.expired => LocaleKeys.matchmaker_cases_stage_photo_expired,
      CaseStageOutcome.closed => LocaleKeys.matchmaker_cases_formal_closed,
      CaseStageOutcome.cancelled => LocaleKeys.matchmaker_cases_formal_cancelled,
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
