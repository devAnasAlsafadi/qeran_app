import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/effects/ring_motif.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'onboarding_glow_pulse.dart';
import 'onboarding_reveal.dart';

/// The marriage journey as a vertical timeline of **4 core milestones** — kept
/// deliberately sparse so the path is aspirational and scannable at a glance
/// (rather than a dense clinical checklist). Wine nodes with a gold ring and
/// gold icon; the final node ("marriage") is gold-filled to celebrate the
/// destination. A subtle gold ring motif sits behind for depth.
///
/// Labels are paper on the wine hero (the endpoint is gold) — the reveal draws
/// each milestone in turn.
class OnboardingRoadmapTimeline extends StatelessWidget {
  const OnboardingRoadmapTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = <(IconData, String)>[
      (
        Icons.person_add_rounded,
        LocaleKeys.onboarding_roadmap_milestone_profile.t(context),
      ),
      (
        Icons.groups_rounded,
        LocaleKeys.onboarding_roadmap_milestone_explore.t(context),
      ),
      (
        Icons.support_agent_rounded,
        LocaleKeys.onboarding_roadmap_milestone_mediation.t(context),
      ),
      (
        Icons.workspace_premium_rounded,
        LocaleKeys.onboarding_roadmap_milestone_marriage.t(context),
      ),
    ];
    return Stack(
      children: [
        const PositionedDirectional(
          top: 0,
          end: -46,
          child: RingMotif(
            color: QeranColors.gold,
            opacity: 0.10,
            size: 200,
            ringCount: 3,
            spacing: 24,
          ),
        ),
        OnboardingReveal(
          // Four milestones — a deliberate cascade so each one lands in turn.
          children: [
            for (var i = 0; i < steps.length; i++)
              _RoadmapNode(
                icon: steps[i].$1,
                label: steps[i].$2,
                isLast: i == steps.length - 1,
              ),
          ],
        ),
      ],
    );
  }
}

class _RoadmapNode extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLast;

  const _RoadmapNode({
    required this.icon,
    required this.label,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 38,
            child: Column(
              children: [
                _NodeCircle(icon: icon, isLast: isLast),
                if (!isLast)
                  const Expanded(
                    child: SizedBox(
                      width: 2,
                      child: ColoredBox(color: QeranColors.gold40),
                    ),
                  ),
              ],
            ),
          ),
          QeranSpacing.hs12,
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                top: QeranSpacing.s8,
                bottom: isLast ? QeranSpacing.s4 : QeranSpacing.s32,
              ),
              child: Text(
                label,
                style: QeranTypography.subtitle.copyWith(
                  color: isLast ? QeranColors.gold : QeranColors.paper,
                  fontWeight: isLast ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeCircle extends StatelessWidget {
  final IconData icon;
  final bool isLast;

  const _NodeCircle({required this.icon, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isLast ? QeranColors.gold : QeranColors.wineLight,
        shape: BoxShape.circle,
        border: Border.all(
          color: isLast ? QeranColors.gold : QeranColors.gold40,
          width: 1.5,
        ),
      ),
      child: Icon(
        icon,
        size: 18,
        color: isLast ? QeranColors.wine : QeranColors.gold,
      ),
    );
    // The destination node breathes a gold halo — the aspiration of the whole
    // journey. Earlier nodes stay quiet.
    if (!isLast) return circle;
    return OnboardingGlowPulse(
      circle: true,
      maxBlur: 18,
      maxSpread: 1,
      child: circle,
    );
  }
}
