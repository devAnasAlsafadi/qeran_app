import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The branded success hero: a wine→wineLight gradient band with concentric
/// gold rings, a dual heart/premium verification badge, and the confirmation
/// copy. [planName] is already resolved to the active locale by the caller.
class PurchaseSuccessHero extends StatelessWidget {
  final String planName;

  const PurchaseSuccessHero({super.key, required this.planName});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [QeranColors.wineLight, QeranColors.wine],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Concentric decorative rings, radiating from the badge.
          const _Ring(size: 280, top: -50, alpha: 0.20, width: 1),
          const _Ring(size: 112, top: 20, alpha: 0.40, width: 1.2),
          const Positioned(top: 48, child: _VerificationBadge()),
          Positioned(
            bottom: QeranSpacing.s48,
            left: QeranSpacing.s24,
            right: QeranSpacing.s24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  LocaleKeys.subscriptions_purchase_success_title.t(context),
                  textAlign: TextAlign.center,
                  style: QeranTypography.headline.copyWith(
                    color: QeranColors.paper,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                QeranSpacing.vs8,
                Text(
                  LocaleKeys.subscriptions_purchase_success_msg
                      .t(context)
                      .replaceFirst('{planName}', planName),
                  textAlign: TextAlign.center,
                  style: QeranTypography.body.copyWith(
                    color: QeranColors.gold.withValues(alpha: 0.80),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One concentric gold outline circle, anchored from the hero top.
class _Ring extends StatelessWidget {
  final double size;
  final double top;
  final double alpha;
  final double width;

  const _Ring({
    required this.size,
    required this.top,
    required this.alpha,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: QeranColors.gold.withValues(alpha: alpha),
            width: width,
          ),
        ),
      ),
    );
  }
}

/// The two overlapping circles — a wine heart + a gold premium seal — that read
/// as "your union is verified / blessed".
class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 56,
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            child: _BadgeCircle(
              color: QeranColors.wine,
              icon: Icons.favorite_rounded,
              iconColor: QeranColors.gold,
            ),
          ),
          Positioned(
            left: 36,
            child: _BadgeCircle(
              color: QeranColors.gold,
              icon: Icons.workspace_premium_rounded,
              iconColor: QeranColors.wine,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCircle extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color iconColor;

  const _BadgeCircle({
    required this.color,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: QeranColors.paper, width: 2),
      ),
      child: Icon(icon, color: iconColor, size: 26),
    );
  }
}
