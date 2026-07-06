import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/effects/ring_motif.dart';
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
import 'onboarding_chat_backdrop.dart';
import 'onboarding_hero_background.dart';
import 'onboarding_matchmaker_glass_card.dart';
import 'onboarding_profile_card_layers.dart';

/// Frame 2 — Dignified Mediation (الوساطة الجادة).
///
/// A frosted matchmaker glass card floats over a blurred chat backdrop and a
/// faint gold ring motif, capped by a soft-white dome with the title / body /
/// highlight copy and the in-dome footer (dots + next). The illustrative search
/// CTA lives inside the card. No network call happens in onboarding.
class OnboardingMediationFrame extends StatelessWidget {
  final int dotCount;
  final int activeDot;
  final ValueChanged<int> onDot;
  final VoidCallback onNext;
  final VoidCallback onSearch;

  const OnboardingMediationFrame({
    super.key,
    required this.dotCount,
    required this.activeDot,
    required this.onDot,
    required this.onNext,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context);
    return OnboardingHeroBackground(
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // The conversation fills the whole upper zone (up under the
                // floating top bar); the card floats over its centre.
                const Positioned.fill(child: OnboardingChatBackdrop()),
                const PositionedDirectional(
                  top: -20,
                  end: -40,
                  child: RingMotif(
                    color: QeranColors.gold,
                    opacity: 0.07,
                    size: 240,
                    ringCount: 3,
                    spacing: 26,
                  ),
                ),
                // Keeps the floating skip / language controls legible.
                const OnboardingCardTopScrim(),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    QeranSpacing.s16,
                    safe.top + 56,
                    QeranSpacing.s16,
                    0,
                  ),
                  child: Center(
                    child: OnboardingMatchmakerGlassCard(onSearch: onSearch),
                  ),
                ),
              ],
            ),
          ),
          _MediationDomePanel(
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

class _MediationDomePanel extends StatelessWidget {
  final double bottomInset;
  final Widget footer;

  const _MediationDomePanel({required this.bottomInset, required this.footer});

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
          OnboardingDomeHeading(
            title: LocaleKeys.onboarding_mediation_title.t(context),
          ),
          QeranSpacing.vs8,
          Text(
            LocaleKeys.onboarding_mediation_body.t(context),
            style: QeranTypography.bodySm,
          ),
          QeranSpacing.vs16,
          OnboardingDomeHighlight(
            icon: Icons.handshake_rounded,
            text: LocaleKeys.onboarding_mediation_highlight.t(context),
          ),
          QeranSpacing.vs16,
          footer,
        ],
      ),
    );
  }
}
