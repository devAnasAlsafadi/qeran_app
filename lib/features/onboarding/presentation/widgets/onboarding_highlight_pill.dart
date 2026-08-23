import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

/// A content-frame reassurance line: a leading gold icon + short copy inside a
/// warm gold container. Shared across onboarding frames.
///
/// The fill is opaque [QeranColors.goldPending] rather than a translucent gold
/// wash: the pill sits on the wine canvas now, where a low-alpha gold would
/// sink into the background and leave the wine text unreadable.
///
/// Radius stays [QeranRadii.controlR] rather than a full pill — the copy wraps
/// to two lines in English, and true pill ends read badly around a block.
class OnboardingHighlightPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const OnboardingHighlightPill({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QeranColors.goldPending,
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
