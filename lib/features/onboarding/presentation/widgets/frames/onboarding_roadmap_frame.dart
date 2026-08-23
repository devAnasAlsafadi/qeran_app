import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../onboarding_nav_row.dart';
import 'onboarding_hero_background.dart';
import 'onboarding_responsive_frame.dart';
import 'onboarding_roadmap_timeline.dart';
import 'onboarding_trust_badges.dart';

/// Frame 3 — Marriage Roadmap (رحلة الزواج).
///
/// A centred header + a flat 10-step journey timeline over the wine canvas,
/// then the trust-badge grid, the nav row and the "begin your journey" CTA,
/// all sitting directly on that canvas — no paper panel, so the screen reads as
/// explanation rather than product. [onFinish] ends onboarding (routes onward).
class OnboardingRoadmapFrame extends StatelessWidget {
  final VoidCallback onFinish;
  final int dotCount;
  final int activeDot;
  final ValueChanged<int> onDot;
  final VoidCallback? onBack;

  const OnboardingRoadmapFrame({
    super.key,
    required this.onFinish,
    required this.dotCount,
    required this.activeDot,
    required this.onDot,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context);
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    return OnboardingHeroBackground(
      child: OnboardingResponsiveFrame(
        hero: CustomScrollView(
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
                  ],
                ),
              ),
            ),
          ],
        ),
        panel: _RoadmapContent(
          topInset: isLandscape
              ? safe.top + QeranSpacing.s64
              : QeranSpacing.s16,
          bottomInset: safe.bottom + QeranSpacing.s16,
          dotCount: dotCount,
          activeDot: activeDot,
          onDot: onDot,
          onBack: onBack,
          onFinish: onFinish,
        ),
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

class _RoadmapContent extends StatelessWidget {
  final double topInset;
  final double bottomInset;
  final int dotCount;
  final int activeDot;
  final ValueChanged<int> onDot;
  final VoidCallback? onBack;
  final VoidCallback onFinish;

  const _RoadmapContent({
    required this.topInset,
    required this.bottomInset,
    required this.dotCount,
    required this.activeDot,
    required this.onDot,
    required this.onBack,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        QeranSpacing.s20,
        topInset,
        QeranSpacing.s20,
        bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const OnboardingTrustBadges(),
          QeranSpacing.vs16,
          // No next here — the full-width CTA below is this frame's action, so
          // the row keeps its end slot empty and the dots stay centred.
          OnboardingNavRow(
            dotCount: dotCount,
            activeDot: activeDot,
            onDot: onDot,
            onBack: onBack,
          ),
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
