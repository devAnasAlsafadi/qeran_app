import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_card.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../onboarding_highlight_pill.dart';
import '../onboarding_nav_row.dart';
import '../onboarding_section_heading.dart';
import 'onboarding_blurred_profile_card.dart';
import 'onboarding_hero_background.dart';
import 'onboarding_privacy_step_strip.dart';
import 'onboarding_responsive_frame.dart';

/// Frame 1 — Essence & Privacy (الجوهر والخصوصية).
///
/// A dominant blurred-profile hero fills the wine canvas. Below it the content
/// sits directly on that canvas — no paper panel — so the screen reads as
/// explanation rather than product: the privacy step strip in a small card of
/// its own, then gold title, paper body, the reassurance pill, and the nav row.
class OnboardingEssenceFrame extends StatelessWidget {
  final int dotCount;
  final int activeDot;
  final ValueChanged<int> onDot;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  const OnboardingEssenceFrame({
    super.key,
    required this.dotCount,
    required this.activeDot,
    required this.onDot,
    required this.onNext,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context);
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    return OnboardingHeroBackground(
      child: OnboardingResponsiveFrame(
        hero: const Padding(
          // Full-bleed to the screen top + sides; the floating top bar rides
          // over the photo (top scrim keeps it legible). Only a small gap
          // before the content below it remains.
          padding: EdgeInsetsDirectional.only(bottom: QeranSpacing.s8),
          child: OnboardingBlurredProfileCard(),
        ),
        panel: _EssenceContent(
          topInset: isLandscape
              ? safe.top + QeranSpacing.s64
              : QeranSpacing.s20,
          bottomInset: safe.bottom + QeranSpacing.s16,
          footer: OnboardingNavRow(
            dotCount: dotCount,
            activeDot: activeDot,
            onDot: onDot,
            onBack: onBack,
            onNext: onNext,
          ),
        ),
      ),
    );
  }
}

class _EssenceContent extends StatelessWidget {
  final double topInset;
  final double bottomInset;
  final Widget footer;

  const _EssenceContent({
    required this.topInset,
    required this.bottomInset,
    required this.footer,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // The strip is the one block that keeps a paper surface: its nodes
          // and captions were drawn for light ground and read nowhere else.
          // Inset from the column so it reads as a card on the canvas rather
          // than a band across it — s12, not more: the strip splits its width
          // across five nodes and the longest label ellipsises if squeezed.
          const QeranCard(
            margin: EdgeInsets.symmetric(horizontal: QeranSpacing.s12),
            padding: EdgeInsets.symmetric(
              horizontal: QeranSpacing.s12,
              vertical: QeranSpacing.s12,
            ),
            child: OnboardingPrivacyStepStrip(),
          ),
          QeranSpacing.vs16,
          OnboardingSectionHeading(
            title: LocaleKeys.onboarding_essence_title.t(context),
          ),
          QeranSpacing.vs8,
          Text(
            LocaleKeys.onboarding_essence_body.t(context),
            style: QeranTypography.bodySm.copyWith(color: QeranColors.paper),
          ),
          QeranSpacing.vs16,
          OnboardingHighlightPill(
            icon: Icons.shield_rounded,
            text: LocaleKeys.onboarding_essence_highlight.t(context),
          ),
          // Lifts the strip, copy and pill together: the panel is
          // bottom-anchored, so widening the gap above the controls raises
          // everything over it while the nav row holds its place.
          QeranSpacing.vs32,
          footer,
        ],
      ),
    );
  }
}
