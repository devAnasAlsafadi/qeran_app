import 'package:flutter/material.dart';

import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/case_stage.dart';
import '../../domain/entities/compatibility_case.dart';

/// Progress of one timeline node relative to the case's current stage.
enum CaseStepState { done, current, future }

/// Colour flavour of the *current* node: a normal in-progress stage, a
/// successful completion, or a non-success ending (rejected / closed /
/// cancelled). Ignored for done / future nodes.
enum CaseStepTone { normal, success, ended }

/// One node of the compatibility-journey timeline: what it says, what it
/// wears, and where the case is relative to it.
///
/// [icon] rides WITH [labelKey] rather than being looked up separately by
/// whoever draws it. The status card used to take its label from the case's
/// raw `stage` and its icon from the same place, which is how an ended case
/// showed «لم ينجح» under a handshake: two properties describing one fact,
/// resolved independently. One object, resolved once, cannot disagree.
///
/// The stepper ignores [icon] — it draws its own node discs. That is a small
/// price for the guarantee.
class CaseTimelineStep {
  const CaseTimelineStep({
    required this.labelKey,
    required this.icon,
    required this.state,
    required this.tone,
  });

  final String labelKey;
  final IconData icon;
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

/// The icon for a node showing its OWN label, one per [CaseStage] in the same
/// order as [caseStageLabelKey]. Kept adjacent to it so a new node cannot gain
/// words without a glyph.
IconData _nodeIcon(CaseStage stage) => switch (stage) {
      CaseStage.likeAccepted => Icons.favorite_border_rounded,
      CaseStage.photoExchange => Icons.photo_camera_outlined,
      CaseStage.waitingAppointment => Icons.event_outlined,
      CaseStage.parentsVisited => Icons.event_available_outlined,
      CaseStage.completed => Icons.verified_outlined,
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

/// The glyph that replaces the node's own when [_overrideLabel] replaces its
/// words. Deliberately the SAME shape as that function — every outcome with an
/// override label has an override icon on the same line, and the two members
/// that keep their node's label keep its icon.
IconData? _overrideIcon(CaseStageOutcome outcome) => switch (outcome) {
      CaseStageOutcome.rejected => Icons.highlight_off_rounded,
      CaseStageOutcome.expired => Icons.timer_off_outlined,
      CaseStageOutcome.closed => Icons.lock_outline_rounded,
      CaseStageOutcome.cancelled => Icons.block_rounded,
      CaseStageOutcome.formalStepPending => Icons.hourglass_top_rounded,
      CaseStageOutcome.formalStepRejected => Icons.cancel_outlined,
      CaseStageOutcome.formalStepExpired => Icons.timer_off_outlined,
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
  final overrideIcon = _overrideIcon(placement.outcome);

  return [
    for (var i = 0; i < CaseStage.values.length; i++)
      CaseTimelineStep(
        labelKey: (i == index && overrideLabel != null)
            ? overrideLabel
            : caseStageLabelKey(CaseStage.values[i]),
        icon: (i == index && overrideIcon != null)
            ? overrideIcon
            : _nodeIcon(CaseStage.values[i]),
        state: i < index
            ? CaseStepState.done
            : i == index
                ? CaseStepState.current
                : CaseStepState.future,
        tone: i == index ? tone : CaseStepTone.normal,
      ),
  ];
}

/// The node the case is standing on — the single reading of "where is this
/// case, and how did it go there".
///
/// The detail screen draws this twice: as the current node of the timeline,
/// and as the «stage» row of the status card. The row used to compute its own
/// answer from the raw `stage` field, which the backend FREEZES once the
/// matchmaker takes a case over, so an ended case still read
/// «بانتظار تنسيق الخطّابة» while the timeline beside it said the
/// case had failed. Two readers of one fact is how they disagreed; this is the
/// one reader.
///
/// Exactly one node is current for every case by construction of
/// [buildCaseTimeline], so the lookup cannot come back empty.
CaseTimelineStep currentCaseStep(CompatibilityCase c) =>
    buildCaseTimeline(c).firstWhere((s) => s.state == CaseStepState.current);
