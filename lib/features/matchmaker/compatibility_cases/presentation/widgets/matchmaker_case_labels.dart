import 'package:flutter/material.dart';

import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/case_photo_exchange_status.dart';
import '../../domain/entities/compatibility_case.dart';
import '../../domain/entities/compatibility_case_stage.dart';
import '../../domain/entities/formal_request_status.dart';
import 'case_timeline.dart';

/// Presentation glue mapping the case enums to their localized label keys
/// and a small status icon. Kept out of the card so the card stays lean.
/// All return `null` for the `unknown` member so the card omits the chip
/// rather than render an empty pill.

String? stageLabelKey(CompatibilityCaseStage stage) => switch (stage) {
      CompatibilityCaseStage.likeAccepted =>
        LocaleKeys.matchmaker_cases_stage_like_accepted,
      CompatibilityCaseStage.photoExchangePending =>
        LocaleKeys.matchmaker_cases_stage_photo_pending,
      CompatibilityCaseStage.photoExchangeAccepted =>
        LocaleKeys.matchmaker_cases_stage_photo_accepted,
      CompatibilityCaseStage.photoExchangeRejected =>
        LocaleKeys.matchmaker_cases_stage_photo_rejected,
      CompatibilityCaseStage.photoExchangeExpired =>
        LocaleKeys.matchmaker_cases_stage_photo_expired,
      CompatibilityCaseStage.formalStepPending =>
        LocaleKeys.matchmaker_cases_stage_formal_step_pending,
      CompatibilityCaseStage.formalStepRejected =>
        LocaleKeys.matchmaker_cases_stage_formal_step_rejected,
      CompatibilityCaseStage.formalStepExpired =>
        LocaleKeys.matchmaker_cases_stage_formal_step_expired,
      CompatibilityCaseStage.awaitingMatchmakerCoordination =>
        LocaleKeys.matchmaker_cases_stage_awaiting_coordination,
      // The same milestone the formal status already names — one string, so
      // the chip cannot disagree with itself depending on which field it read.
      CompatibilityCaseStage.parentsVisited =>
        LocaleKeys.matchmaker_cases_formal_parents_visited,
      CompatibilityCaseStage.marriageCompleted =>
        LocaleKeys.matchmaker_cases_formal_successfully_closed,
      CompatibilityCaseStage.unknown => null,
    };

IconData? stageIcon(CompatibilityCaseStage stage) => switch (stage) {
      CompatibilityCaseStage.likeAccepted => Icons.favorite_border_rounded,
      CompatibilityCaseStage.photoExchangePending => Icons.schedule_rounded,
      CompatibilityCaseStage.photoExchangeAccepted =>
        Icons.check_circle_outline_rounded,
      CompatibilityCaseStage.photoExchangeRejected =>
        Icons.highlight_off_rounded,
      CompatibilityCaseStage.photoExchangeExpired => Icons.timer_off_outlined,
      CompatibilityCaseStage.formalStepPending => Icons.hourglass_top_rounded,
      CompatibilityCaseStage.formalStepRejected => Icons.cancel_outlined,
      CompatibilityCaseStage.formalStepExpired => Icons.timer_off_outlined,
      CompatibilityCaseStage.awaitingMatchmakerCoordination =>
        Icons.handshake_outlined,
      // Matching formalStatusIcon for the same two milestones.
      CompatibilityCaseStage.parentsVisited => Icons.event_available_outlined,
      CompatibilityCaseStage.marriageCompleted => Icons.verified_outlined,
      CompatibilityCaseStage.unknown => null,
    };

String? formalStatusLabelKey(FormalRequestStatus status) => switch (status) {
      FormalRequestStatus.waitingForParentAppointment =>
        LocaleKeys.matchmaker_cases_formal_waiting_appointment,
      FormalRequestStatus.parentsVisited =>
        LocaleKeys.matchmaker_cases_formal_parents_visited,
      FormalRequestStatus.successfullyClosed =>
        LocaleKeys.matchmaker_cases_formal_successfully_closed,
      FormalRequestStatus.compatibilityClosed =>
        LocaleKeys.matchmaker_cases_formal_closed,
      FormalRequestStatus.compatibilityCancelled =>
        LocaleKeys.matchmaker_cases_formal_cancelled,
      FormalRequestStatus.unknown => null,
    };

IconData? formalStatusIcon(FormalRequestStatus status) => switch (status) {
      FormalRequestStatus.waitingForParentAppointment => Icons.event_outlined,
      FormalRequestStatus.parentsVisited => Icons.event_available_outlined,
      FormalRequestStatus.successfullyClosed => Icons.verified_outlined,
      FormalRequestStatus.compatibilityClosed => Icons.lock_outline_rounded,
      FormalRequestStatus.compatibilityCancelled => Icons.block_rounded,
      FormalRequestStatus.unknown => null,
    };

String? photoStatusLabelKey(CasePhotoExchangeStatus status) => switch (status) {
      CasePhotoExchangeStatus.pending =>
        LocaleKeys.matchmaker_cases_photo_status_pending,
      CasePhotoExchangeStatus.accepted =>
        LocaleKeys.matchmaker_cases_photo_status_accepted,
      CasePhotoExchangeStatus.rejected =>
        LocaleKeys.matchmaker_cases_photo_status_rejected,
      CasePhotoExchangeStatus.expired =>
        LocaleKeys.matchmaker_cases_photo_status_expired,
      CasePhotoExchangeStatus.unknown => null,
    };

/// Imperative button label for a status-update target, using an action verb
/// rather than the state label.
///
/// The negative terminal is now ONE action, so the old "إغلاق" / "إلغاء" split
/// is gone: both closed and cancelled read "إغلاق الحالة". A bare "إلغاء" was
/// the worst of the two anyway — it is also the dismiss button on the confirm
/// dialog that opens right on top of it.
///
/// Only `parentsVisited`, `successfullyClosed` and `compatibilityCancelled`
/// are reachable; the rest never appear in `allowedNext`.
String actionLabelKey(FormalRequestStatus target) => switch (target) {
      FormalRequestStatus.parentsVisited =>
        LocaleKeys.matchmaker_cases_action_parents_visited,
      FormalRequestStatus.successfullyClosed =>
        LocaleKeys.matchmaker_cases_action_successfully_closed,
      FormalRequestStatus.compatibilityClosed ||
      FormalRequestStatus.compatibilityCancelled ||
      FormalRequestStatus.waitingForParentAppointment ||
      FormalRequestStatus.unknown =>
        LocaleKeys.matchmaker_cases_action_close_case,
    };

/// Every status a case can be moved TO, in the order they are offered. These
/// are the only members that ever appear in an `allowedNext`; the rest are
/// either the starting state or display-only.
const List<FormalRequestStatus> statusUpdateTargets = [
  FormalRequestStatus.parentsVisited,
  FormalRequestStatus.successfullyClosed,
  FormalRequestStatus.compatibilityCancelled,
];

/// The timeline step the case is standing on. Drives the informative "why is
/// there nothing to do here" message in both the detail screen's no-actions
/// card and the list card's update sheet, so the two cannot drift.
CaseStepTone currentCaseTone(CompatibilityCase c) {
  for (final step in buildCaseTimeline(c)) {
    if (step.state == CaseStepState.current) return step.tone;
  }
  return CaseStepTone.normal;
}

String noActionsMessageKey(CaseStepTone tone) => switch (tone) {
  CaseStepTone.success => LocaleKeys.matchmaker_cases_no_actions_complete,
  CaseStepTone.ended => LocaleKeys.matchmaker_cases_no_actions_ended,
  CaseStepTone.normal => LocaleKeys.matchmaker_cases_no_actions_waiting,
};

/// Terminal closures that must be confirmed before submitting.
bool isDestructiveTarget(FormalRequestStatus target) =>
    target == FormalRequestStatus.compatibilityClosed ||
    target == FormalRequestStatus.compatibilityCancelled;
