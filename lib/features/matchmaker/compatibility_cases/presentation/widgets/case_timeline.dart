import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/compatibility_case.dart';
import '../../domain/entities/compatibility_case_stage.dart';
import '../../domain/entities/formal_request_status.dart';

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

/// The five canonical happy-path nodes, in order. Nodes 0–1 come from the
/// case `stage`, nodes 2–4 from `formalRequest.status` — collapsing the
/// photo-pending/accepted sub-states into a single "photo exchange" node.
/// The labels are the SAME keys the status card and filter sheet (08) use.
const List<String> _canonicalLabelKeys = [
  LocaleKeys.matchmaker_cases_stage_like_accepted,
  LocaleKeys.matchmaker_cases_field_photo_exchange,
  LocaleKeys.matchmaker_cases_formal_waiting_appointment,
  LocaleKeys.matchmaker_cases_formal_parents_visited,
  LocaleKeys.matchmaker_cases_formal_successfully_closed,
];

/// Projects a live [CompatibilityCase] onto the canonical timeline.
///
/// Determination (backend truth): the current node is derived from
/// `formalRequest.status` when a formal request exists, otherwise from the
/// case `stage`. Nodes before the current one are [CaseStepState.done], the
/// current one carries a [CaseStepTone] (normal / success / ended), and later
/// ones are [CaseStepState.future].
///
/// Off-happy-path terminals keep the honest label: a rejected/expired photo
/// exchange ends at the photo node; a closed/cancelled formal request is
/// anchored at the first formal node (the payload doesn't say whether it left
/// from "waiting" or "visited" — the exact status still shows in the status
/// card) with its real closed/cancelled label.
List<CaseTimelineStep> buildCaseTimeline(CompatibilityCase c) {
  int currentIndex;
  var tone = CaseStepTone.normal;
  String? overrideLabel;

  final formal = c.formalRequest;
  if (formal != null) {
    switch (formal.status) {
      case FormalRequestStatus.waitingForParentAppointment:
        currentIndex = 2;
      case FormalRequestStatus.parentsVisited:
        currentIndex = 3;
      case FormalRequestStatus.successfullyClosed:
        currentIndex = 4;
        tone = CaseStepTone.success;
      case FormalRequestStatus.compatibilityClosed:
        currentIndex = 2;
        tone = CaseStepTone.ended;
        overrideLabel = LocaleKeys.matchmaker_cases_formal_closed;
      case FormalRequestStatus.compatibilityCancelled:
        currentIndex = 2;
        tone = CaseStepTone.ended;
        overrideLabel = LocaleKeys.matchmaker_cases_formal_cancelled;
      case FormalRequestStatus.unknown:
        currentIndex = 2;
    }
  } else {
    switch (c.stage) {
      case CompatibilityCaseStage.likeAccepted:
        currentIndex = 0;
      case CompatibilityCaseStage.photoExchangePending:
        currentIndex = 1;
      // Photos accepted but no formal request yet — the formal track is about
      // to begin; sit at the first formal node.
      case CompatibilityCaseStage.photoExchangeAccepted:
        currentIndex = 2;
      case CompatibilityCaseStage.photoExchangeRejected:
        currentIndex = 1;
        tone = CaseStepTone.ended;
        overrideLabel = LocaleKeys.matchmaker_cases_stage_photo_rejected;
      case CompatibilityCaseStage.photoExchangeExpired:
        currentIndex = 1;
        tone = CaseStepTone.ended;
        overrideLabel = LocaleKeys.matchmaker_cases_stage_photo_expired;
      case CompatibilityCaseStage.unknown:
        currentIndex = 0;
    }
  }

  return [
    for (var i = 0; i < _canonicalLabelKeys.length; i++)
      CaseTimelineStep(
        labelKey: (i == currentIndex && overrideLabel != null)
            ? overrideLabel
            : _canonicalLabelKeys[i],
        state: i < currentIndex
            ? CaseStepState.done
            : i == currentIndex
                ? CaseStepState.current
                : CaseStepState.future,
        tone: i == currentIndex ? tone : CaseStepTone.normal,
      ),
  ];
}
