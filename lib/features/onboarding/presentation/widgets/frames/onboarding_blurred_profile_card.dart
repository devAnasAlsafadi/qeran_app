import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'onboarding_profile_meta_overlay.dart';
import 'onboarding_split_blur_portrait.dart';

/// The privacy hero as one dominant card. A sample profile (Sara) whose photo
/// is split diagonally from frosted to clear — demoing the gradual-unblur
/// mechanic — with the name/age + category chips integrated over a wine scrim
/// and the gold lock note riding the frosted half.
class OnboardingBlurredProfileCard extends StatelessWidget {
  const OnboardingBlurredProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 420,
      decoration: BoxDecoration(
        borderRadius: QeranRadii.cardR,
        border: Border.all(color: QeranColors.gold40),
      ),
      clipBehavior: Clip.antiAlias,
      child: const Stack(
        fit: StackFit.expand,
        children: [
          OnboardingSplitBlurPortrait(),
          _BottomScrim(),
          _LockNote(),
          Positioned(
            left: QeranSpacing.s16,
            right: QeranSpacing.s16,
            bottom: QeranSpacing.s16,
            child: OnboardingProfileMetaOverlay(),
          ),
        ],
      ),
    );
  }
}

/// A wine gradient shielding the lower card so the paper meta stays legible
/// over both the clear and the frosted pixels behind it.
class _BottomScrim extends StatelessWidget {
  const _BottomScrim();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 220,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 1.0],
              colors: [
                QeranColors.wine.withValues(alpha: 0),
                QeranColors.wine.withValues(alpha: 0.92),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The gold lock + privacy note, centred over the frosted half.
class _LockNote extends StatelessWidget {
  const _LockNote();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: QeranSpacing.s24,
      left: QeranSpacing.s24,
      right: QeranSpacing.s24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, color: QeranColors.gold, size: 28),
          QeranSpacing.vs8,
          Text(
            LocaleKeys.onboarding_essence_lock_note.t(context),
            textAlign: TextAlign.center,
            style: QeranTypography.caption.copyWith(color: QeranColors.paper),
          ),
        ],
      ),
    );
  }
}
