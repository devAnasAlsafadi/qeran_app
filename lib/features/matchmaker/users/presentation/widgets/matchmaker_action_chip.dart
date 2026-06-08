import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_loader.dart';

/// A slim Figma-style action chip — matchmaker-scoped (NOT the shared
/// QeranButton, whose `xs` size is intentionally chunkier and used elsewhere).
/// Content-sized by construction (`Row(min)`, no expanding `Center`), so it
/// flows naturally in a parent [Wrap] without an `IntrinsicWidth`. Filled
/// `wine` for a list's primary action, soft `softFill` chip otherwise. Mirrors
/// automatically (RTL/LTR). While [loading] the icon becomes an inline loader
/// and taps are suppressed.
class MatchmakerActionChip extends StatelessWidget {
  const MatchmakerActionChip({
    super.key,
    required this.label,
    required this.icon,
    required this.primary,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool primary;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? QeranColors.paper : QeranColors.wine;
    final bg = primary ? QeranColors.wine : QeranColors.softFill;
    return Material(
      color: bg,
      borderRadius: QeranRadii.pill,
      child: InkWell(
        borderRadius: QeranRadii.pill,
        onTap: loading ? null : onTap,
        splashColor: fg.withValues(alpha: 0.08),
        highlightColor: fg.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: QeranSpacing.s12,
            vertical: QeranSpacing.s6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 15,
                height: 15,
                child: loading
                    ? FittedBox(child: QeranLoader.inline(color: fg))
                    : Icon(icon, size: 15, color: fg),
              ),
              const SizedBox(width: QeranSpacing.s6),
              Text(
                label,
                style: QeranTypography.label.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
