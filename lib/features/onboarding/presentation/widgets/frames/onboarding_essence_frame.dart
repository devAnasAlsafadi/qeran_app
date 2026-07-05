import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'onboarding_hero_background.dart';
import 'onboarding_blurred_profile_card.dart';
import 'onboarding_privacy_step_strip.dart';

/// Frame 1 — Essence & Privacy (الجوهر والخصوصية).
///
/// A scrollable hero area (the blurred profile card + the privacy step strip)
/// over the cream canvas, capped by a soft-white bottom panel carrying the
/// title / body / highlight copy. Top and bottom padding clear the wizard's
/// floating chrome (top bar / bottom nav).
class OnboardingEssenceFrame extends StatelessWidget {
  const OnboardingEssenceFrame({super.key});

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
              child: const Column(
                children: [
                  OnboardingBlurredProfileCard(),
                  QeranSpacing.vs20,
                  OnboardingPrivacyStepStrip(),
                ],
              ),
            ),
          ),
          _EssenceTextPanel(bottomInset: safe.bottom + 84),
        ],
      ),
    );
  }
}

class _EssenceTextPanel extends StatelessWidget {
  final double bottomInset;

  const _EssenceTextPanel({required this.bottomInset});

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
        QeranSpacing.s24,
        QeranSpacing.s24,
        bottomInset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LocaleKeys.onboarding_essence_title.t(context),
            style: QeranTypography.headline.copyWith(color: QeranColors.wine),
          ),
          QeranSpacing.vs8,
          Text(
            LocaleKeys.onboarding_essence_body.t(context),
            style: QeranTypography.body,
          ),
          QeranSpacing.vs16,
          const _Highlight(),
        ],
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: QeranColors.gold12,
        borderRadius: QeranRadii.controlR,
      ),
      padding: const EdgeInsets.all(QeranSpacing.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: QeranColors.goldDeep,
            size: 18,
          ),
          QeranSpacing.hs8,
          Expanded(
            child: Text(
              LocaleKeys.onboarding_essence_highlight.t(context),
              style: QeranTypography.bodySm.copyWith(color: QeranColors.wine),
            ),
          ),
        ],
      ),
    );
  }
}
