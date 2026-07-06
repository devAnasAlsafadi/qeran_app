import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The roadmap dome's reassurance grid: four trust badges in two columns, each a
/// gold-deep check + a short line.
class OnboardingTrustBadges extends StatelessWidget {
  const OnboardingTrustBadges({super.key});

  @override
  Widget build(BuildContext context) {
    final badges = <String>[
      LocaleKeys.onboarding_roadmap_badge_reviewed.t(context),
      LocaleKeys.onboarding_roadmap_badge_consent.t(context),
      LocaleKeys.onboarding_roadmap_badge_orderly.t(context),
      LocaleKeys.onboarding_roadmap_badge_assisted.t(context),
    ];
    return Column(
      children: [
        for (var i = 0; i < badges.length; i += 2) ...[
          if (i > 0) QeranSpacing.vs8,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Badge(text: badges[i])),
              QeranSpacing.hs12,
              Expanded(child: _Badge(text: badges[i + 1])),
            ],
          ),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: QeranColors.goldDeep,
          size: 17,
        ),
        QeranSpacing.hs4,
        Expanded(
          child: Text(
            text,
            style: QeranTypography.caption.copyWith(color: QeranColors.inkBody),
          ),
        ),
      ],
    );
  }
}
