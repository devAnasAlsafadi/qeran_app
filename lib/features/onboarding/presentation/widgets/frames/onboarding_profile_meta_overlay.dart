import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The profile identity layer that rides the bottom of the portrait card: the
/// name + age paired with a "verified identity" badge, then the four category
/// chips. Paper text over the card's wine scrim keeps it legible whether the
/// pixels behind are clear or frosted.
class OnboardingProfileMetaOverlay extends StatelessWidget {
  const OnboardingProfileMetaOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [const _NameRow(), QeranSpacing.vs12, const _InfoChips()],
    );
  }
}

class _NameRow extends StatelessWidget {
  const _NameRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            LocaleKeys.onboarding_essence_person_name.t(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: QeranTypography.subtitle.copyWith(color: QeranColors.paper),
          ),
        ),
        QeranSpacing.hs8,
        // Age is a numeric cluster — pinned LTR + tabular figures.
        Text(
          LocaleKeys.onboarding_essence_person_age.t(context),
          textDirection: TextDirection.ltr,
          style: QeranTypography.numeric.copyWith(color: QeranColors.gold),
        ),
        QeranSpacing.hs8,
        // "Verified identity" badge replaces the former initial disc.
        QeranChip(
          icon: Icons.verified_rounded,
          label: LocaleKeys.onboarding_essence_identity_badge.t(context),
          variant: QeranChipVariant.status,
          statusColor: QeranColors.gold,
          compact: true,
        ),
      ],
    );
  }
}

class _InfoChips extends StatelessWidget {
  const _InfoChips();

  @override
  Widget build(BuildContext context) {
    final chips = <(IconData, String, String)>[
      (
        Icons.school_rounded,
        LocaleKeys.onboarding_essence_chip_education_label.t(context),
        LocaleKeys.onboarding_essence_chip_education_value.t(context),
      ),
      (
        Icons.work_rounded,
        LocaleKeys.onboarding_essence_chip_work_label.t(context),
        LocaleKeys.onboarding_essence_chip_work_value.t(context),
      ),
      (
        Icons.mosque_rounded,
        LocaleKeys.onboarding_essence_chip_religiosity_label.t(context),
        LocaleKeys.onboarding_essence_chip_religiosity_value.t(context),
      ),
      (
        // Nationality chip — globe glyph (the former heart suited "goal").
        Icons.public_rounded,
        LocaleKeys.onboarding_essence_chip_goal_label.t(context),
        LocaleKeys.onboarding_essence_chip_goal_value.t(context),
      ),
    ];
    return Wrap(
      spacing: QeranSpacing.s8,
      runSpacing: QeranSpacing.s8,
      children: [
        for (final (icon, label, value) in chips)
          QeranChip(
            icon: icon,
            iconColor: QeranColors.gold,
            label: '$label · $value',
            variant: QeranChipVariant.glass,
            compact: true,
          ),
      ],
    );
  }
}
