import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/widgets/language_switch_button.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The content-frame top bar: a **Skip** control at the start and the language
/// switch at the end. Rendered over the cream canvas (frames 1–3), so it uses
/// wine ink + the labelled (dark) language pill.
///
/// Fully bidirectional — the outer `Row` mirrors automatically, and the Skip
/// double-chevron is flipped to follow the reading direction.
class OnboardingTopBar extends StatelessWidget {
  final VoidCallback onSkip;

  /// Whether to show the Skip control. Hidden on the last frame (roadmap),
  /// where the language switch stays pinned to the end edge.
  final bool showSkip;

  const OnboardingTopBar({
    super.key,
    required this.onSkip,
    this.showSkip = true,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s20,
        vertical: QeranSpacing.s8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showSkip)
            _SkipButton(onTap: onSkip, isRtl: isRtl)
          else
            const SizedBox.shrink(),
          const LanguageSwitchButton(variant: LanguageSwitchVariant.light),
        ],
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isRtl;

  const _SkipButton({required this.onTap, required this.isRtl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LocaleKeys.onboarding_skip.t(context),
            style: QeranTypography.label.copyWith(color: QeranColors.paper),
          ),
          QeranSpacing.hs4,
          // Points toward the reading end (→ in LTR, ← in RTL).
          Transform.flip(
            flipX: isRtl,
            child: const Icon(
              Icons.keyboard_double_arrow_right_rounded,
              size: 18,
              color: QeranColors.paper,
            ),
          ),
        ],
      ),
    );
  }
}
