import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The marriage journey as a vertical 5-step timeline riding a gold spine:
/// matchmaker assigned → profile review → discover matches → photo control →
/// guidance until marriage. The nodes distribute evenly down the available
/// height (the spine runs unbroken behind them); each is a wine circle (gold
/// ring + gold icon) with a title + a supporting subtitle.
class OnboardingRoadmapTimeline extends StatelessWidget {
  const OnboardingRoadmapTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = <(IconData, String, String)>[
      (
        Icons.support_agent_rounded,
        LocaleKeys.onboarding_roadmap_step1_title.t(context),
        LocaleKeys.onboarding_roadmap_step1_sub.t(context),
      ),
      (
        Icons.verified_user_rounded,
        LocaleKeys.onboarding_roadmap_step2_title.t(context),
        LocaleKeys.onboarding_roadmap_step2_sub.t(context),
      ),
      (
        Icons.person_search_rounded,
        LocaleKeys.onboarding_roadmap_step3_title.t(context),
        LocaleKeys.onboarding_roadmap_step3_sub.t(context),
      ),
      (
        Icons.blur_on_rounded,
        LocaleKeys.onboarding_roadmap_step4_title.t(context),
        LocaleKeys.onboarding_roadmap_step4_sub.t(context),
      ),
      (
        Icons.favorite_rounded,
        LocaleKeys.onboarding_roadmap_step5_title.t(context),
        LocaleKeys.onboarding_roadmap_step5_sub.t(context),
      ),
    ];
    return Stack(
      children: [
        // The gold spine, running unbroken behind the node circles from the
        // first node's centre to the last's, on the start edge.
        const PositionedDirectional(
          start: 18,
          top: 19,
          bottom: 19,
          child: SizedBox(
            width: 2.5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: QeranRadii.pill,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [QeranColors.gold, QeranColors.gold40],
                ),
              ),
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0) QeranSpacing.vs24,
              _RoadmapNode(
                icon: steps[i].$1,
                title: steps[i].$2,
                sub: steps[i].$3,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _RoadmapNode extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;

  const _RoadmapNode({
    required this.icon,
    required this.title,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: QeranColors.wine,
            border: Border.all(color: QeranColors.gold, width: 1.5),
            boxShadow: QeranShadows.e2,
          ),
          child: Icon(icon, color: QeranColors.gold, size: 19),
        ),
        QeranSpacing.hs12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: QeranTypography.label.copyWith(
                  color: QeranColors.paper,
                ),
              ),
              QeranSpacing.vs4,
              Text(
                sub,
                style: QeranTypography.caption.copyWith(
                  color: QeranColors.gold.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
