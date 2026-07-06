import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'onboarding_profile_card_layers.dart';
import 'onboarding_profile_meta_overlay.dart';
import 'onboarding_split_blur_portrait.dart';

/// The privacy hero — a full-bleed sample portrait (Sara) whose photo carries a
/// baked-in split from frosted to clear, with a top scrim for the floating
/// chrome, a gold lock badge over the frosted half, and the name/age + category
/// chips integrated over a wine scrim at the base. It bleeds to the screen top;
/// the dome surfaces beneath it.
class OnboardingBlurredProfileCard extends StatelessWidget {
  const OnboardingBlurredProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          OnboardingSplitBlurPortrait(),
          OnboardingCardFullOverlay(),
          OnboardingCardTopScrim(),
          OnboardingCardSplitDivider(),
          OnboardingCardBottomScrim(),
          _LockBadge(),
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

/// The gold lock disc + privacy note, centred over the frosted half (~40%).
class _LockBadge extends StatelessWidget {
  const _LockBadge();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: QeranColors.gold,
                shape: BoxShape.circle,
                boxShadow: QeranShadows.eHero,
              ),
              child: const Icon(
                Icons.visibility_off_rounded,
                color: QeranColors.wine,
                size: 22,
              ),
            ),
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
