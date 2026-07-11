import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/design_system/widgets/qeran_section_header.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/case_photo_exchange_status.dart';
import '../../domain/entities/compatibility_case.dart';
import 'matchmaker_case_labels.dart';

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

    final stageKey = stageLabelKey(caseItem.stage);
    if (stageKey != null) {
      rows.add(_StatusRow(
        icon: stageIcon(caseItem.stage) ?? Icons.timeline_rounded,
        labelKey: LocaleKeys.matchmaker_cases_field_stage,
        value: stageKey.t(context),
        valueColor: QeranColors.inkStrong,
      ));
    }

    final formal = caseItem.formalRequest;
    if (formal != null) {
      final key = formalStatusLabelKey(formal.status);
      if (key != null) {
        rows.add(_StatusRow(
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
        rows.add(_StatusRow(
          icon: Icons.photo_camera_outlined,
          labelKey: LocaleKeys.matchmaker_cases_field_photo_exchange,
          value: key.t(context),
          valueColor: _photoColor(pe.status),
        ));
      }
    }

    final accepted = caseItem.likeAcceptedAt;
    if (accepted != null) {
      rows.add(_StatusRow(
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
                if (i > 0) const _RowDivider(),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

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

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.labelKey,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final String labelKey;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: QeranColors.wine06,
            borderRadius: QeranRadii.xsR,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: QeranColors.wine),
        ),
        QeranSpacing.hs12,
        Expanded(
          child: Text(labelKey.t(context), style: QeranTypography.caption),
        ),
        QeranSpacing.hs12,
        Flexible(
          child: Text(
            value,
            style: QeranTypography.label.copyWith(color: valueColor),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: QeranSpacing.s12),
      child: Divider(height: 1, color: QeranColors.divider),
    );
  }
}
