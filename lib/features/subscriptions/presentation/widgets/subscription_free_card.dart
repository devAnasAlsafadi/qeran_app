import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/effects/ring_motif.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Shown on the My-subscription screen when `/current` is null — the user has
/// NO subscription yet (NOT "on Free"; the free trial is activated explicitly
/// from the packages screen). A wine-gradient hero inviting them to activate
/// the free trial or pick a plan.
class SubscriptionFreeCard extends StatelessWidget {
  const SubscriptionFreeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: QeranRadii.panelR,
        boxShadow: QeranShadows.eHero,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [QeranColors.wineLight, QeranColors.wine],
        ),
      ),
      padding: const EdgeInsets.all(QeranSpacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const _CrownBadge(),
              QeranSpacing.hs16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      LocaleKeys.subscriptions_none_title.t(context),
                      style: QeranTypography.title
                          .copyWith(color: QeranColors.paper),
                    ),
                    QeranSpacing.vs4,
                    Text(
                      LocaleKeys.subscriptions_none_body.t(context),
                      style: QeranTypography.bodySm
                          .copyWith(color: QeranColors.gold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          QeranSpacing.vs20,
          QeranButton(
            label: LocaleKeys.subscriptions_view_packages_cta.t(context),
            variant: QeranButtonVariant.primaryGold,
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: () =>
                NavigationManager.navigateTo(context, RouteNames.packagesScreen),
          ),
        ],
      ),
    );
  }
}

class _CrownBadge extends StatelessWidget {
  const _CrownBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const RingMotif(
            color: QeranColors.gold,
            opacity: 0.18,
            size: 56,
            ringCount: 1,
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: QeranColors.gold.withValues(alpha: 0.18),
              border: Border.all(color: QeranColors.gold, width: 1.2),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: QeranColors.gold,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
