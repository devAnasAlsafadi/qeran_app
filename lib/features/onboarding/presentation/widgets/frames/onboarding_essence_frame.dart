import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../onboarding_dome_footer.dart';
import '../onboarding_dome_heading.dart';
import '../onboarding_dome_highlight.dart';
import 'onboarding_blurred_profile_card.dart';
import 'onboarding_hero_background.dart';
import 'onboarding_privacy_step_strip.dart';

/// Frame 1 — Essence & Privacy (الجوهر والخصوصية).
///
/// A dominant blurred-profile hero fills the wine canvas, capped by a soft-white
/// dome carrying the privacy step strip, the title / body / highlight copy, and
/// the in-dome footer (dots + next). The hero clears the floating top bar; the
/// dome owns the frame's navigation.
class OnboardingEssenceFrame extends StatelessWidget {
  final int dotCount;
  final int activeDot;
  final ValueChanged<int> onDot;
  final VoidCallback onNext;

  const OnboardingEssenceFrame({
    super.key,
    required this.dotCount,
    required this.activeDot,
    required this.onDot,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context);
    return OnboardingHeroBackground(
      child: Column(
        children: [
          const Expanded(
            child: Padding(
              // Full-bleed to the screen top + sides; the floating top bar rides
              // over the photo (top scrim keeps it legible). Only a small gap
              // before the dome remains.
              padding: EdgeInsetsDirectional.only(bottom: QeranSpacing.s8),
              child: OnboardingBlurredProfileCard(),
            ),
          ),
          _EssenceDomePanel(
            bottomInset: safe.bottom + QeranSpacing.s16,
            footer: OnboardingDomeFooter(
              dotCount: dotCount,
              activeDot: activeDot,
              onDot: onDot,
              onNext: onNext,
            ),
          ),
        ],
      ),
    );
  }
}

class _EssenceDomePanel extends StatelessWidget {
  final double bottomInset;
  final Widget footer;

  const _EssenceDomePanel({required this.bottomInset, required this.footer});

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
        QeranSpacing.s20,
        QeranSpacing.s20,
        bottomInset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const OnboardingPrivacyStepStrip(),
          QeranSpacing.vs16,
          OnboardingDomeHeading(
            title: LocaleKeys.onboarding_essence_title.t(context),
          ),
          QeranSpacing.vs8,
          Text(
            LocaleKeys.onboarding_essence_body.t(context),
            style: QeranTypography.bodySm,
          ),
          QeranSpacing.vs16,
          OnboardingDomeHighlight(
            icon: Icons.shield_rounded,
            text: LocaleKeys.onboarding_essence_highlight.t(context),
          ),
          QeranSpacing.vs16,
          footer,
        ],
      ),
    );
  }
}
