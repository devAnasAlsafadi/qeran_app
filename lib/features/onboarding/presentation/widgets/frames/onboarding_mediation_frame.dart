import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'onboarding_hero_background.dart';
import 'onboarding_matchmaker_glass_card.dart';
import 'onboarding_mediation_blocks.dart';

/// Frame 2 — Dignified Mediation (الوساطة الجادة).
///
/// A scrollable hero (the glassmorphic matchmaker card + the mediation status
/// flow) over the cream canvas, capped by a soft-white bottom panel with the
/// title / body / highlight and the (illustrative) "search with the matchmaker"
/// CTA. Padding clears the wizard's floating chrome.
class OnboardingMediationFrame extends StatelessWidget {
  /// Fired by the (illustrative) "search with the matchmaker" CTA — the screen
  /// wires it to advance to the next frame so the flow stays walkable. No
  /// network call happens in onboarding.
  final VoidCallback onSearch;

  const OnboardingMediationFrame({super.key, required this.onSearch});

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
                safe.top + 76,
                QeranSpacing.s20,
                QeranSpacing.s16,
              ),
              child: const Column(
                children: [
                  OnboardingMatchmakerGlassCard(),
                  QeranSpacing.vs20,
                  OnboardingMediationBlocks(),
                ],
              ),
            ),
          ),
          _MediationTextPanel(bottomInset: safe.bottom + 84, onSearch: onSearch),
        ],
      ),
    );
  }
}

class _MediationTextPanel extends StatelessWidget {
  final double bottomInset;
  final VoidCallback onSearch;

  const _MediationTextPanel({
    required this.bottomInset,
    required this.onSearch,
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
            LocaleKeys.onboarding_mediation_title.t(context),
            style: QeranTypography.headline.copyWith(color: QeranColors.wine),
          ),
          QeranSpacing.vs8,
          Text(
            LocaleKeys.onboarding_mediation_body.t(context),
            style: QeranTypography.body,
          ),
          QeranSpacing.vs12,
          const _Highlight(),
          QeranSpacing.vs16,
          QeranButton(
            label: LocaleKeys.onboarding_mediation_search_cta.t(context),
            leadingIcon: Icons.search_rounded,
            // Illustrative — advances to the roadmap frame so the prototype
            // flows end-to-end. No network call in onboarding.
            onPressed: onSearch,
          ),
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
            Icons.workspace_premium_rounded,
            color: QeranColors.goldDeep,
            size: 18,
          ),
          QeranSpacing.hs8,
          Expanded(
            child: Text(
              LocaleKeys.onboarding_mediation_highlight.t(context),
              style: QeranTypography.bodySm.copyWith(color: QeranColors.wine),
            ),
          ),
        ],
      ),
    );
  }
}
