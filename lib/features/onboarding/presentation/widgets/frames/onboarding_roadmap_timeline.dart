import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The marriage journey as a vertical 9-step timeline riding a gold spine:
/// create profile → answer questions → hidden photo → matchmaker approval →
/// search → mutual interest → photo reveal → contact → family details. Each is
/// a flat row — a wine circle (gold ring + gold icon) + a single label, no
/// descriptive sub-line. The unbroken spine runs behind the circles; the
/// "الزواج الشرعي" rings capstone (in the frame) completes the journey as step
/// ten.
class OnboardingRoadmapTimeline extends StatelessWidget {
  const OnboardingRoadmapTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = <(IconData, String)>[
      (Icons.person_add_alt_1_rounded, LocaleKeys.onboarding_roadmap_step1.t(context)),
      (Icons.quiz_rounded, LocaleKeys.onboarding_roadmap_step2.t(context)),
      (Icons.hide_image_rounded, LocaleKeys.onboarding_roadmap_step3.t(context)),
      (Icons.verified_rounded, LocaleKeys.onboarding_roadmap_step4.t(context)),
      (Icons.person_search_rounded, LocaleKeys.onboarding_roadmap_step5.t(context)),
      (Icons.favorite_rounded, LocaleKeys.onboarding_roadmap_step6.t(context)),
      (Icons.visibility_rounded, LocaleKeys.onboarding_roadmap_step7.t(context)),
      (Icons.forum_rounded, LocaleKeys.onboarding_roadmap_step8.t(context)),
      (Icons.diversity_3_rounded, LocaleKeys.onboarding_roadmap_step9.t(context)),
    ];
    return Stack(
      children: [
        // The gold spine, running unbroken behind the node circles from the
        // first node's centre to the last's, on the start edge.
        const PositionedDirectional(
          start: 16,
          top: 17,
          bottom: 17,
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
              if (i > 0) QeranSpacing.vs8,
              _RoadmapNode(icon: steps[i].$1, label: steps[i].$2),
            ],
          ],
        ),
      ],
    );
  }
}

class _RoadmapNode extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RoadmapNode({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: QeranColors.wine,
            border: Border.all(color: QeranColors.gold, width: 1.5),
            boxShadow: QeranShadows.e2,
          ),
          child: Icon(icon, color: QeranColors.gold, size: 18),
        ),
        QeranSpacing.hs12,
        Expanded(
          child: Text(
            label,
            style: QeranTypography.label.copyWith(color: QeranColors.paper),
          ),
        ),
      ],
    );
  }
}
