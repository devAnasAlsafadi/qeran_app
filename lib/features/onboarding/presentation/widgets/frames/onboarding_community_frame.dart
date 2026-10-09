import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/effects/ring_motif.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../onboarding_highlight_pill.dart';
import '../onboarding_nav_row.dart';
import '../onboarding_section_heading.dart';
import 'onboarding_community_card.dart';
import 'onboarding_ghost_cards.dart';
import 'onboarding_hero_background.dart';
import 'onboarding_responsive_frame.dart';

/// Frame 1 — Community (المجتمع): «تعلّم قبل أن تخطو».
///
/// The first thing a new member sees, so it introduces the first tab: a card
/// of the matchmakers' guidance over faint posts and the gold ring motif, then
/// the title, body, callout and nav row on the wine canvas. The same shape as
/// frame 2, whose heading, pill and nav row it shares.
///
/// The illustration is decoration and is hidden from screen readers: its
/// topics and names are examples.
class OnboardingCommunityFrame extends StatelessWidget {
  final int dotCount;
  final int activeDot;
  final ValueChanged<int> onDot;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  const OnboardingCommunityFrame({
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
        // Under the floating skip / language row, as frame 2's card.
        hero: _CommunityHero(topInset: safe.top + 56),
        panel: _CommunityContent(
          padding: EdgeInsetsDirectional.fromSTEB(
            QeranSpacing.s20,
            isLandscape ? safe.top + QeranSpacing.s64 : QeranSpacing.s20,
            QeranSpacing.s20,
            safe.bottom + QeranSpacing.s16,
          ),
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

class _CommunityHero extends StatelessWidget {
  final double topInset;

  const _CommunityHero({required this.topInset});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Stack(
        children: [
          // Three rings round one centre, 60 in from the end edge and 80 down
          // from the top; the outer two run off the frame.
          const PositionedDirectional(
            top: -90,
            end: -110,
            child: RingMotif(
              opacity: 0.10,
              size: 340,
              ringCount: 3,
              spacing: 50,
            ),
          ),
          const Positioned.fill(child: OnboardingGhostCards()),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              QeranSpacing.s24,
              topInset,
              QeranSpacing.s24,
              QeranSpacing.s16,
            ),
            child: const _FittedCard(),
          ),
        ],
      ),
    );
  }
}

/// The card at the hero's full width, centred, and scaled down whole when a
/// short screen leaves it less height than it needs — never clipped.
class _FittedCard extends StatelessWidget {
  const _FittedCard();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: constraints.maxWidth,
            child: const OnboardingCommunityCard(),
          ),
        ),
      ),
    );
  }
}

/// Frame 2's rhythm: the panel is bottom-anchored, so the gap above the nav
/// row is what lifts the copy off it.
class _CommunityContent extends StatelessWidget {
  final EdgeInsetsDirectional padding;
  final Widget footer;

  const _CommunityContent({required this.padding, required this.footer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          OnboardingSectionHeading(
            title: LocaleKeys.onboarding_community_title.t(context),
          ),
          QeranSpacing.vs16,
          Text(
            LocaleKeys.onboarding_community_body.t(context),
            style: QeranTypography.bodySm.copyWith(color: QeranColors.paper),
          ),
          QeranSpacing.vs20,
          OnboardingHighlightPill(
            icon: Icons.verified_user_rounded,
            text: LocaleKeys.onboarding_community_highlight.t(context),
          ),
          QeranSpacing.vs48,
          footer,
        ],
      ),
    );
  }
}
