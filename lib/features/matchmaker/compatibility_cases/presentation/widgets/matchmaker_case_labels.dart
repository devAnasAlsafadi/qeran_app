import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
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

/// The colour "kind" of a case's overall status, driving the list card's
/// differentiated status chip. Derived from the formal-request status when
/// present, else the stage — the same precedence the timeline uses.
enum CaseStatusKind { active, waiting, expired, closed }

CaseStatusKind caseStatusKind(CompatibilityCase c) {
  final formal = c.formalRequest;
  if (formal != null) {
    switch (formal.status) {
      case FormalRequestStatus.waitingForParentAppointment:
      case FormalRequestStatus.parentsVisited:
      case FormalRequestStatus.successfullyClosed:
        return CaseStatusKind.active;
      case FormalRequestStatus.compatibilityClosed:
      case FormalRequestStatus.compatibilityCancelled:
        return CaseStatusKind.closed;
      case FormalRequestStatus.unknown:
        return CaseStatusKind.waiting;
    }
  }
  switch (c.stage) {
    case CompatibilityCaseStage.likeAccepted:
    case CompatibilityCaseStage.photoExchangePending:
    case CompatibilityCaseStage.photoExchangeAccepted:
      return CaseStatusKind.waiting;
    case CompatibilityCaseStage.photoExchangeRejected:
      return CaseStatusKind.closed;
    case CompatibilityCaseStage.photoExchangeExpired:
      return CaseStatusKind.expired;
    case CompatibilityCaseStage.unknown:
      return CaseStatusKind.waiting;
  }
}

/// Per-kind chip palette (background / foreground / border / leading dot) for
/// the list card's status chip — the four visually distinct kinds from 05.
({Color bg, Color fg, Color border, Color dot}) caseStatusKindPalette(
  CaseStatusKind kind,
) =>
    switch (kind) {
      CaseStatusKind.active => (
          bg: QeranColors.gold12,
          fg: QeranColors.goldDeep,
          border: QeranColors.gold40,
          dot: QeranColors.goldDeep,
        ),
      CaseStatusKind.waiting => (
          bg: QeranColors.wine06,
          fg: QeranColors.wine,
          border: QeranColors.wine12,
          dot: QeranColors.wine,
        ),
      CaseStatusKind.expired => (
          bg: QeranColors.softFill,
          fg: QeranColors.inkMuted,
          border: Colors.transparent,
          dot: QeranColors.inkMuted,
        ),
      CaseStatusKind.closed => (
          bg: QeranColors.danger12,
          fg: QeranColors.danger,
          border: QeranColors.danger40,
          dot: QeranColors.danger,
        ),
    };

/// The single most-specific status label for the card chip: the formal-request
/// status once on the formal track, otherwise the stage. `null` (no chip) when
/// the value is unknown.
String? caseStatusChipLabelKey(CompatibilityCase c) {
  final formal = c.formalRequest;
  if (formal != null) return formalStatusLabelKey(formal.status);
  return stageLabelKey(c.stage);
}
