import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../domain/entities/compatibility_case.dart';
import '../../domain/entities/compatibility_case_stage.dart';
import '../../domain/entities/formal_request_status.dart';
import 'matchmaker_case_labels.dart';

/// The list card's status chip: which of the four visual kinds a case reads
/// as, the palette that paints it, and the single label it carries.
///
/// Split out of `matchmaker_case_labels.dart`, which had grown past the file
/// cap. That file stays the enum → label-key/icon glue; this one owns the
/// derived chip, which is the only place those mappings get combined with
/// colour.

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
    case CompatibilityCaseStage.formalStepPending:
      return CaseStatusKind.waiting;
    case CompatibilityCaseStage.formalStepRejected:
      return CaseStatusKind.closed;
    case CompatibilityCaseStage.formalStepExpired:
      return CaseStatusKind.expired;
    // On the formal track and moving. These are normally reached through the
    // formalRequest branch above; kept in step with it so the chip does not
    // change colour depending on which field answered.
    case CompatibilityCaseStage.awaitingMatchmakerCoordination:
    case CompatibilityCaseStage.parentsVisited:
    case CompatibilityCaseStage.marriageCompleted:
      return CaseStatusKind.active;
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
