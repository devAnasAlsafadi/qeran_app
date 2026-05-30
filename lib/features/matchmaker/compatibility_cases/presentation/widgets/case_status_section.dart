import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/compatibility_case.dart';
import 'matchmaker_case_labels.dart';

/// Read-only status block for the case detail: stage, formal-request status
/// (when present), photo-exchange status (when present) and the like-accepted
/// date — each a labelled row. The detail view can afford every signal at
/// once, unlike the scannable list card.
class CaseStatusSection extends StatelessWidget {
  const CaseStatusSection({super.key, required this.caseItem});

  final CompatibilityCase caseItem;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    final stageKey = stageLabelKey(caseItem.stage);
    if (stageKey != null) {
      rows.add(_StatusRow(
        labelKey: LocaleKeys.matchmaker_cases_field_stage,
        value: stageKey.t(context),
      ));
    }

    final formal = caseItem.formalRequest;
    if (formal != null) {
      final key = formalStatusLabelKey(formal.status);
      if (key != null) {
        rows.add(_StatusRow(
          labelKey: LocaleKeys.matchmaker_cases_field_formal_status,
          value: key.t(context),
        ));
      }
    }

    final pe = caseItem.photoExchange;
    if (pe != null) {
      final key = photoStatusLabelKey(pe.status);
      if (key != null) {
        rows.add(_StatusRow(
          labelKey: LocaleKeys.matchmaker_cases_field_photo_exchange,
          value: key.t(context),
        ));
      }
    }

    final accepted = caseItem.likeAcceptedAt;
    if (accepted != null) {
      rows.add(_StatusRow(
        labelKey: LocaleKeys.matchmaker_cases_field_like_accepted,
        value: _formatDate(accepted),
      ));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return QeranCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LocaleKeys.matchmaker_cases_section_status.t(context),
            style: QeranTypography.title,
          ),
          QeranSpacing.vs12,
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const _RowDivider(),
            rows[i],
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}/$m/$day';
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.labelKey, required this.value});

  final String labelKey;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(labelKey.t(context), style: QeranTypography.caption),
        ),
        QeranSpacing.hs12,
        Flexible(
          child: Text(
            value,
            style: QeranTypography.label,
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
