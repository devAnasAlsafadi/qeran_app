import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/app_assets.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The privacy hero: a sample profile whose photo stays **blurred**. A real
/// profile portrait sits behind a heavy `BackdropFilter` frost (plus a
/// translucent veil to simulate the design's `saturate`), so it reads as a
/// person behind premium glass rather than a technical blackout. A lock note
/// over it, then the name/age and the floating info chips beneath.
class OnboardingBlurredProfileCard extends StatelessWidget {
  const OnboardingBlurredProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BlurredAvatar(),
        QeranSpacing.vs16,
        _NameRow(),
        QeranSpacing.vs12,
        _InfoChips(),
      ],
    );
  }
}

class _BlurredAvatar extends StatelessWidget {
  const _BlurredAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: QeranRadii.cardR,
        border: Border.all(color: QeranColors.gold40),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 168,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Wine base — tints the portrait and backs its transparent corners.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [QeranColors.wine, QeranColors.wineLight],
                ),
              ),
            ),
            // A real profile portrait — the "someone" behind the glass.
            Image.asset(AppAssets.male, fit: BoxFit.cover),
            // Frost + veil (blur ≈ design's 13px; veil ≈ saturate).
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: const ColoredBox(color: QeranColors.wine20),
            ),
            // Top-lit glass rim — lifts the card off the wine hero behind it.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.35],
                    colors: [
                      QeranColors.gold20,
                      QeranColors.gold.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            const _LockNote(),
          ],
        ),
      ),
    );
  }
}

class _LockNote extends StatelessWidget {
  const _LockNote();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, color: QeranColors.gold, size: 26),
            QeranSpacing.vs8,
            Text(
              LocaleKeys.onboarding_essence_lock_note.t(context),
              textAlign: TextAlign.center,
              style: QeranTypography.caption.copyWith(color: QeranColors.paper),
            ),
          ],
        ),
      ),
    );
  }
}

class _NameRow extends StatelessWidget {
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
        DecoratedBox(
          decoration: const BoxDecoration(
            color: QeranColors.creamSurface,
            borderRadius: QeranRadii.pill,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: QeranSpacing.s12,
              vertical: QeranSpacing.s2,
            ),
            // Age is a numeric cluster — pinned LTR + tabular figures.
            child: Text(
              LocaleKeys.onboarding_essence_person_age.t(context),
              textDirection: TextDirection.ltr,
              style: QeranTypography.numeric.copyWith(color: QeranColors.wine),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoChips extends StatelessWidget {
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
        Icons.favorite_rounded,
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
            label: '$label · $value',
            variant: QeranChipVariant.meta,
          ),
      ],
    );
  }
}
