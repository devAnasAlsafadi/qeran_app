import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../domain/entities/compatibility_case.dart';
import 'case_timeline.dart';
import 'matchmaker_case_labels.dart';


/// The no-actions informative card — cream-surface + a tinted icon chip that
/// explains WHY there's nothing to do, tied to the timeline's current step:
/// complete (success) · ended (rejected/closed/cancelled) · awaiting the other
/// party (still in progress but not this matchmaker's turn / pre-formal).
class CaseNoActionsCard extends StatelessWidget {
  const CaseNoActionsCard({super.key, required this.caseItem});

  final CompatibilityCase caseItem;

  @override
  Widget build(BuildContext context) {
    final tone = currentCaseTone(caseItem);
    final (:icon, :accent, :bg) = _style(tone);
    final messageKey = noActionsMessageKey(tone);

    return Container(
      padding: const EdgeInsets.all(QeranSpacing.s16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: QeranRadii.cardR,
        border: Border.all(color: accent, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: QeranRadii.controlR,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: accent),
          ),
          QeranSpacing.hs12,
          Expanded(
            child: Text(
              messageKey.t(context),
              style: QeranTypography.subtitle,
            ),
          ),
        ],
      ),
    );
  }

  // The message itself comes from `noActionsMessageKey`, shared with the list
  // card's update sheet; only the styling stays local to this card.
  ({IconData icon, Color accent, Color bg}) _style(CaseStepTone tone) =>
      switch (tone) {
        CaseStepTone.success => (
            icon: Icons.verified_rounded,
            accent: QeranColors.goldDeep,
            bg: QeranColors.creamSurface,
          ),
        CaseStepTone.ended => (
            icon: Icons.flag_rounded,
            accent: QeranColors.wine,
            bg: QeranColors.creamSurface,
          ),
        CaseStepTone.normal => (
            icon: Icons.hourglass_top_rounded,
            accent: QeranColors.goldDeep,
            bg: QeranColors.creamSurface,
          ),
      };
}
