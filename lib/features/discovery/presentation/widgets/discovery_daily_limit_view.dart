import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/motion/soft_scale_in.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_hero_badge.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'reset_countdown.dart';

/// Full-screen "come back tomorrow" state shown inside Discover when a
/// no-subscription user hits the daily view cap (`DAILY_VIEWS_EXCEEDED`). NOT a
/// paywall — it pairs a live reset countdown with an optional upgrade nudge.
/// Renders within the discovery shell, so the bottom nav stays visible.
class DiscoveryDailyLimitView extends StatelessWidget {
  final DateTime resetAt;
  const DiscoveryDailyLimitView({super.key, required this.resetAt});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: QeranSpacing.s32,
          vertical: QeranSpacing.s24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: SoftScaleIn(
                  child: QeranHeroBadge(
                    glyph: Icons.visibility_rounded,
                    tone: QeranHeroBadgeTone.prominent,
                    size: 104,
                  ),
                ),
              ),
              QeranSpacing.vs20,
              Text(
                LocaleKeys.discovery_daily_limit_title.t(context),
                textAlign: TextAlign.center,
                style: QeranTypography.headline.copyWith(
                  color: QeranColors.wine,
                  fontWeight: FontWeight.w800,
                ),
              ),
              QeranSpacing.vs8,
              Text(
                LocaleKeys.discovery_daily_limit_subtitle.t(context),
                textAlign: TextAlign.center,
                style: QeranTypography.body.copyWith(color: QeranColors.inkBody),
              ),
              QeranSpacing.vs16,
              Center(child: ResetCountdown(resetAt: resetAt)),
              QeranSpacing.vs24,
              const _Hairline(),
              QeranSpacing.vs20,
              Text(
                LocaleKeys.discovery_daily_limit_upgrade_heading.t(context),
                textAlign: TextAlign.center,
                style: QeranTypography.subtitle.copyWith(
                  color: QeranColors.wine,
                  fontWeight: FontWeight.w700,
                ),
              ),
              QeranSpacing.vs8,
              Text(
                LocaleKeys.discovery_daily_limit_upgrade_support.t(context),
                textAlign: TextAlign.center,
                style: QeranTypography.bodySm.copyWith(
                  color: QeranColors.inkMuted,
                ),
              ),
              QeranSpacing.vs16,
              QeranButton(
                label: LocaleKeys.discovery_daily_limit_cta.t(context),
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: () => NavigationManager.navigateTo(
                  context,
                  RouteNames.packagesScreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft gradient hairline separating the reset message from the upgrade nudge.
class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            QeranColors.hairline.withValues(alpha: 0),
            QeranColors.hairline,
            QeranColors.hairline,
            QeranColors.hairline.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.2, 0.8, 1.0],
        ),
      ),
    );
  }
}
