import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../custom_dot_indicator.dart';
import 'onboarding_hero_background.dart';
import 'onboarding_marriage_destination.dart';
import 'onboarding_roadmap_timeline.dart';
import 'onboarding_trust_badges.dart';

/// Frame 3 — Marriage Roadmap (رحلة الزواج).
///
/// A centred header + a flat 9-step journey timeline capped by the
/// interlocking-rings "الزواج الشرعي" destination (step ten) over the wine
/// canvas, then a soft-white dome carrying the page dots, the trust-badge grid,
/// and the "begin your journey" CTA. [onFinish] ends onboarding (routes onward).
class OnboardingRoadmapFrame extends StatelessWidget {
  final VoidCallback onFinish;
  final int dotCount;
  final int activeDot;
  final ValueChanged<int> onDot;

  const OnboardingRoadmapFrame({
    super.key,
    required this.onFinish,
    required this.dotCount,
    required this.activeDot,
    required this.onDot,
  });

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context);
    return OnboardingHeroBackground(
      child: Column(
        children: [
          Expanded(
            // Slivers avoid the expensive IntrinsicHeight double-layout that
            // used to run while page 3 was sliding into view.
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    QeranSpacing.s24,
                    safe.top + 52,
                    QeranSpacing.s24,
                    QeranSpacing.s16,
                  ),
                  sliver: const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(),
                        QeranSpacing.vs16,
                        OnboardingRoadmapTimeline(),
                        QeranSpacing.vs8,
                        OnboardingMarriageDestination(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _RoadmapDomePanel(
            bottomInset: safe.bottom + QeranSpacing.s16,
            dotCount: dotCount,
            activeDot: activeDot,
            onDot: onDot,
            onFinish: onFinish,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          LocaleKeys.onboarding_roadmap_title.t(context),
          textAlign: TextAlign.center,
          style: QeranTypography.headline.copyWith(color: QeranColors.gold),
        ),
        QeranSpacing.vs4,
        Text(
          LocaleKeys.onboarding_roadmap_subtitle.t(context),
          textAlign: TextAlign.center,
          style: QeranTypography.bodySm.copyWith(
            color: QeranColors.paper.withValues(alpha: 0.82),
          ),
        ),
      ],
    );
  }
}

class _RoadmapDomePanel extends StatelessWidget {
  final double bottomInset;
  final int dotCount;
  final int activeDot;
  final ValueChanged<int> onDot;
  final VoidCallback onFinish;

  const _RoadmapDomePanel({
    required this.bottomInset,
    required this.dotCount,
    required this.activeDot,
    required this.onDot,
    required this.onFinish,
  });

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
        QeranSpacing.s20,
        QeranSpacing.s16,
        QeranSpacing.s20,
        bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: CustomDotIndicator(
              count: dotCount,
              activeIndex: activeDot,
              onTap: onDot,
            ),
          ),
          QeranSpacing.vs16,
          const OnboardingTrustBadges(),
          QeranSpacing.vs16,
          QeranButton(
            label: LocaleKeys.onboarding_roadmap_cta.t(context),
            trailingIcon: Icons.favorite_rounded,
            onPressed: onFinish,
          ),
        ],
      ),
    );
  }
}
