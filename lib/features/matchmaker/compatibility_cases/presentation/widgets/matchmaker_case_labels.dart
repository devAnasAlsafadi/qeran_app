import 'package:flutter/material.dart';

import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/case_photo_exchange_status.dart';
import '../../domain/entities/compatibility_case_stage.dart';
import '../../domain/entities/formal_request_status.dart';

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

/// Imperative button label for a status-update target. The two closures use
/// action verbs ("إغلاق" / "إلغاء") rather than their state labels. The two
/// non-target values are unreachable (never in `allowedNext`).
String actionLabelKey(FormalRequestStatus target) => switch (target) {
      FormalRequestStatus.parentsVisited =>
        LocaleKeys.matchmaker_cases_action_parents_visited,
      FormalRequestStatus.successfullyClosed =>
        LocaleKeys.matchmaker_cases_action_successfully_closed,
      FormalRequestStatus.compatibilityClosed =>
        LocaleKeys.matchmaker_cases_action_close,
      FormalRequestStatus.compatibilityCancelled =>
        LocaleKeys.matchmaker_cases_action_cancel,
      FormalRequestStatus.waitingForParentAppointment ||
      FormalRequestStatus.unknown =>
        LocaleKeys.matchmaker_cases_action_close,
    };

/// Terminal closures that must be confirmed before submitting.
bool isDestructiveTarget(FormalRequestStatus target) =>
    target == FormalRequestStatus.compatibilityClosed ||
    target == FormalRequestStatus.compatibilityCancelled;
