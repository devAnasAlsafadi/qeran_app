import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

/// A content-frame dome highlight: a leading gold icon + a short reassurance
/// line inside a gold-tinted box. Shared across onboarding frames.
class OnboardingDomeHighlight extends StatelessWidget {
  final IconData icon;
  final String text;

  const OnboardingDomeHighlight({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QeranColors.gold12,
        borderRadius: QeranRadii.controlR,
        border: Border.all(color: QeranColors.gold40),
      ),
      padding: const EdgeInsets.all(QeranSpacing.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: QeranColors.goldDeep, size: 18),
          QeranSpacing.hs8,
          Expanded(
            child: Text(
              text,
              style: QeranTypography.bodySm.copyWith(color: QeranColors.wine),
            ),
          ),
        ],
      ),
    );
  }
}
