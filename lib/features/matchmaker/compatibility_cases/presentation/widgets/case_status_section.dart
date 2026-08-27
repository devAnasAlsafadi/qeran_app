import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/design_system/widgets/qeran_section_header.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/case_photo_exchange_status.dart';
import '../../domain/entities/compatibility_case.dart';
import '../../domain/entities/compatibility_case_stage.dart';
import '../../domain/entities/formal_request_status.dart';
import 'case_status_row.dart';
import 'case_timeline.dart';
import 'matchmaker_case_labels.dart';
import 'matchmaker_case_status_kind.dart';

/// Read-only status block for the case detail: a gold-bar header + a paper
/// card of labelled rows (stage · formal-request status · photo-exchange ·
/// accepted-on date). Each row is rendered ONLY when its value is backed —
/// a wine-06 icon chip + ink-muted label + a color-coded value. The detail
/// view can afford every signal at once, unlike the scannable list card.
class CaseStatusSection extends StatelessWidget {
  const CaseStatusSection({super.key, required this.caseItem});

  final CompatibilityCase caseItem;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    // Read off the SAME projection the timeline above draws, rather than the
    // raw `stage` field. The backend freezes that field once the matchmaker
    // takes a case over, so an ended case kept reporting «بانتظار تنسيق
    // الخطّابة» here while the timeline two widgets up already said «لم ينجح».
    //
    // Label, icon and colour all come off one [CaseTimelineStep], so the row
    // cannot half-update the way it did when the icon was looked up separately.
    if (_hasBackedPlacement(caseItem)) {
      final step = currentCaseStep(caseItem);
      rows.add(CaseStatusRow(
        icon: step.icon,
        labelKey: LocaleKeys.matchmaker_cases_field_stage,
        value: step.labelKey.t(context),
        // The stepper's own rule for its current node, so the two readings of
        // one case are the same colour as well as the same words.
        valueColor: step.tone == CaseStepTone.ended
            ? QeranColors.danger
            : QeranColors.inkStrong,
      ));
    }

    final formal = caseItem.formalRequest;
    if (formal != null) {
      final key = formalStatusLabelKey(formal.status);
      if (key != null) {
        rows.add(CaseStatusRow(
          icon: formalStatusIcon(formal.status) ?? Icons.assignment_outlined,
          labelKey: LocaleKeys.matchmaker_cases_field_formal_status,
          value: key.t(context),
          valueColor: caseStatusKindPalette(caseStatusKind(caseItem)).fg,
        ));
      }
    }

    final pe = caseItem.photoExchange;
    if (pe != null) {
      final key = photoStatusLabelKey(pe.status);
      if (key != null) {
        rows.add(CaseStatusRow(
          icon: Icons.photo_camera_outlined,
          labelKey: LocaleKeys.matchmaker_cases_field_photo_exchange,
          value: key.t(context),
          valueColor: _photoColor(pe.status),
        ));
      }
    }

    final accepted = caseItem.likeAcceptedAt;
    if (accepted != null) {
      rows.add(CaseStatusRow(
        icon: Icons.event_rounded,
        labelKey: LocaleKeys.matchmaker_cases_field_like_accepted,
        value: _formatDate(accepted),
        valueColor: QeranColors.inkBody,
      ));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        QeranSectionHeader(
          title: LocaleKeys.matchmaker_cases_section_status.t(context),
        ),
        QeranSpacing.vs8,
        QeranCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const CaseStatusRowDivider(),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Whether anything actually backs a placement.
  ///
  /// `caseStagePlacement` answers for every input, mapping an unreadable case
  /// onto the first node — fine for a timeline, which has to draw five nodes
  /// regardless, but this row has the option of saying nothing and must take
  /// it. Announcing «التوافق الأولي» because a string failed to parse invents
  /// a position for a couple.
  ///
  /// One readable source is enough: a case whose `stage` is unrecognised but
  /// whose formal request is not is still genuinely placed, and vice versa.
  bool _hasBackedPlacement(CompatibilityCase c) =>
      c.stage != CompatibilityCaseStage.unknown ||
      (c.formalRequest != null &&
          c.formalRequest!.status != FormalRequestStatus.unknown);

  Color _photoColor(CasePhotoExchangeStatus status) => switch (status) {
        CasePhotoExchangeStatus.accepted => QeranColors.goldDeep,
        CasePhotoExchangeStatus.rejected => QeranColors.danger,
        CasePhotoExchangeStatus.expired => QeranColors.inkMuted,
        CasePhotoExchangeStatus.pending => QeranColors.wine,
        CasePhotoExchangeStatus.unknown => QeranColors.inkBody,
      };

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}/$m/$day';
  }
}
