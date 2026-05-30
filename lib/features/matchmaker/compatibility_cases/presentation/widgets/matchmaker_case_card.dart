import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/design_system/widgets/qeran_chip.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/compatibility_case.dart';
import 'case_participants_pair.dart';
import 'matchmaker_case_labels.dart';

/// One compatibility-case card: the two participants (via the shared
/// [CaseParticipantsPair]) under a single status chip — the formal-request
/// status when the case has reached the formal track (gold), otherwise the
/// stage (muted). A muted line shows when the like was accepted. Tappable →
/// the case detail (3b).
class MatchmakerCaseCard extends StatelessWidget {
  const MatchmakerCaseCard({super.key, required this.caseItem, this.onTap});

  final CompatibilityCase caseItem;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusChip = _statusChip(context);
    final dateLine = _dateLine(context);
    return QeranCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: QeranSpacing.s12),
      padding: const EdgeInsets.all(QeranSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statusChip != null) ...[statusChip, QeranSpacing.vs16],
          CaseParticipantsPair(
            myUser: caseItem.myUser,
            otherUser: caseItem.otherUser,
          ),
          if (dateLine != null) ...[QeranSpacing.vs16, dateLine],
        ],
      ),
    );
  }

  /// The single primary signal: the formal-request status (gold "interest"
  /// chip) once the case reaches the formal track, otherwise the stage
  /// (muted "meta" chip). `null` when the value is unknown — no chip.
  Widget? _statusChip(BuildContext context) {
    final formal = caseItem.formalRequest;
    final String? labelKey;
    final IconData? icon;
    final QeranChipVariant variant;
    if (formal != null) {
      labelKey = formalStatusLabelKey(formal.status);
      icon = formalStatusIcon(formal.status);
      variant = QeranChipVariant.interest;
    } else {
      labelKey = stageLabelKey(caseItem.stage);
      icon = stageIcon(caseItem.stage);
      variant = QeranChipVariant.meta;
    }
    if (labelKey == null) return null;
    return QeranChip(label: labelKey.t(context), variant: variant, icon: icon);
  }

  Widget? _dateLine(BuildContext context) {
    final d = caseItem.likeAcceptedAt;
    if (d == null) return null;
    final text =
        '${LocaleKeys.matchmaker_cases_like_accepted_at.t(context)} '
        '${_formatDate(d)}';
    return Center(child: Text(text, style: QeranTypography.caption));
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}/$m/$day';
  }
}
