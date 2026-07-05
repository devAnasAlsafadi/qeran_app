import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'onboarding_glow_pulse.dart';
import 'onboarding_hero_background.dart';
import 'onboarding_roadmap_timeline.dart';

/// Frame 3 — Marriage Roadmap (رحلة الزواج).
///
/// A scrollable header + 10-node journey timeline + gold trust badges over the
/// cream canvas, capped by a soft-white panel carrying the primary
/// "begin your journey" CTA. [onFinish] ends onboarding (routes onward).
class OnboardingRoadmapFrame extends StatelessWidget {
  final VoidCallback onFinish;

  const OnboardingRoadmapFrame({super.key, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context);
    return OnboardingHeroBackground(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsetsDirectional.fromSTEB(
                QeranSpacing.s20,
                safe.top + 52,
                QeranSpacing.s20,
                QeranSpacing.s16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocaleKeys.onboarding_roadmap_title.t(context),
                    style: QeranTypography.displaySm.copyWith(
                      color: QeranColors.paper,
                    ),
                  ),
                  QeranSpacing.vs8,
                  Text(
                    LocaleKeys.onboarding_roadmap_subtitle.t(context),
                    style: QeranTypography.body.copyWith(
                      color: QeranColors.gold,
                    ),
                  ),
                  QeranSpacing.vs24,
                  const OnboardingRoadmapTimeline(),
                  QeranSpacing.vs24,
                  const _TrustBadges(),
                ],
              ),
            ),
          ),
          _RoadmapCtaPanel(bottomInset: safe.bottom + 84, onFinish: onFinish),
        ],
      ),
    );
  }
}

class _TrustBadges extends StatelessWidget {
  const _TrustBadges();

  @override
  Widget build(BuildContext context) {
    final badges = <String>[
      LocaleKeys.onboarding_roadmap_badge_reviewed.t(context),
      LocaleKeys.onboarding_roadmap_badge_consent.t(context),
      LocaleKeys.onboarding_roadmap_badge_orderly.t(context),
      LocaleKeys.onboarding_roadmap_badge_assisted.t(context),
    ];
    return Wrap(
      spacing: QeranSpacing.s8,
      runSpacing: QeranSpacing.s8,
      children: [
        for (final badge in badges)
          QeranChip(
            icon: Icons.check_circle_rounded,
            label: badge,
            variant: QeranChipVariant.meta,
          ),
      ],
    );
  }
}

class _RoadmapCtaPanel extends StatelessWidget {
  final double bottomInset;
  final VoidCallback onFinish;

  const _RoadmapCtaPanel({required this.bottomInset, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: QeranColors.paper,
        borderRadius: QeranRadii.domeTop,
        boxShadow: QeranShadows.eLiftUp,
      ),
      padding: EdgeInsetsDirectional.fromSTEB(
        QeranSpacing.s24,
        QeranSpacing.s20,
        QeranSpacing.s24,
        bottomInset,
      ),
      // A faint idle pulse invites the tap without shouting.
      child: OnboardingGlowPulse(
        borderRadius: QeranRadii.controlR,
        maxBlur: 24,
        maxSpread: 1,
        scaleAmount: 0.012,
        child: QeranButton(
          label: LocaleKeys.onboarding_roadmap_cta.t(context),
          trailingIcon: Icons.favorite_rounded,
          onPressed: onFinish,
        ),
      ),
    );
  }
}
