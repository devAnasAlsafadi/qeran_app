import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/effects/ring_motif.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The 10-step marriage journey as a vertical timeline. Wine nodes with a gold
/// ring and gold icon; the final node ("marriage") is gold-filled to celebrate
/// the destination. A subtle gold ring motif sits behind for depth.
///
/// Labels are wine ink (readable on the cream canvas) — a deliberate identity
/// adaptation of the design's dark-panel node text.
class OnboardingRoadmapTimeline extends StatelessWidget {
  const OnboardingRoadmapTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = <(IconData, String)>[
      (Icons.person_add_rounded, LocaleKeys.onboarding_roadmap_step_profile.t(context)),
      (Icons.quiz_rounded, LocaleKeys.onboarding_roadmap_step_questions.t(context)),
      (Icons.blur_on_rounded, LocaleKeys.onboarding_roadmap_step_photo.t(context)),
      (Icons.verified_rounded, LocaleKeys.onboarding_roadmap_step_approved.t(context)),
      (Icons.groups_rounded, LocaleKeys.onboarding_roadmap_step_explore.t(context)),
      (Icons.favorite_rounded, LocaleKeys.onboarding_roadmap_step_interest.t(context)),
      (Icons.visibility_rounded, LocaleKeys.onboarding_roadmap_step_photos_consent.t(context)),
      (Icons.forum_rounded, LocaleKeys.onboarding_roadmap_step_questions_mm.t(context)),
      (Icons.diversity_3_rounded, LocaleKeys.onboarding_roadmap_step_families.t(context)),
      (Icons.workspace_premium_rounded, LocaleKeys.onboarding_roadmap_step_marriage.t(context)),
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
        Column(
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
                bottom: isLast ? QeranSpacing.s4 : QeranSpacing.s20,
              ),
              child: Text(
                label,
                style: QeranTypography.subtitle.copyWith(
                  color: isLast ? QeranColors.goldDeep : QeranColors.wine,
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
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isLast ? QeranColors.gold : QeranColors.wine,
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
  }
}
