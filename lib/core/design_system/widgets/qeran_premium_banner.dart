import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_radii.dart';
import '../tokens/qeran_shadows.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';
import 'qeran_button.dart';

/// Hero gold-on-wine banner. Used at the top of paywalls, upgrade prompts,
/// and active-subscription surfaces.
class QeranPremiumBanner extends StatelessWidget {
  const QeranPremiumBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCta,
    this.icon = Icons.workspace_premium_rounded,
  });

  final String title;
  final String subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: QeranRadii.panelR,
        boxShadow: QeranShadows.eHero,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A1F38), QeranColors.wine],
        ),
      ),
      padding: const EdgeInsets.all(QeranSpacing.s24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _GoldDisc(icon: icon),
          QeranSpacing.hs16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: QeranTypography.title
                      .copyWith(color: QeranColors.paper),
                ),
                QeranSpacing.vs4,
                Text(
                  subtitle,
                  style: QeranTypography.bodySm
                      .copyWith(color: QeranColors.gold),
                ),
                if (ctaLabel != null && onCta != null) ...[
                  QeranSpacing.vs16,
                  QeranButton(
                    label: ctaLabel!,
                    onPressed: onCta,
                    variant: QeranButtonVariant.primary,
                    size: QeranButtonSize.sm,
                    fullWidth: false,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldDisc extends StatelessWidget {
  const _GoldDisc({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: QeranColors.gold.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: QeranColors.gold, width: 1.2),
      ),
      child: Icon(icon, color: QeranColors.gold, size: 28),
    );
  }
}
