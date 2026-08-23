import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'custom_dot_indicator.dart';
import 'onboarding_circle_button.dart';

/// Onboarding's navigation row: **back** at the start, page dots centred, a
/// labelled **next** at the end. Plain `Row`, so it mirrors automatically —
/// back lands on the right in Arabic and the left in English.
///
/// Back stays a bare chevron because it is the secondary move; next carries its
/// word, since it is the one control a first-time user has to find.
///
/// Either control can be absent: [onBack] is null on the first page (nothing to
/// go back to) and [onNext] is null on the last, where a full-width CTA is the
/// action instead. The two side slots take equal flex, so the dots sit dead
/// centre however wide the next label runs — which matters here, because
/// "التالي" and "Next" are not the same width.
///
/// All callbacks are pure, so the row stays decoupled from the cubit.
class OnboardingNavRow extends StatelessWidget {
  /// Fixed width for the next button. Pinned rather than left to the label so
  /// the control keeps the same footprint in both languages — a user's spatial
  /// memory of where the button sits outlives a few pixels of tighter fit.
  static const double _nextWidth = 104;

  final int dotCount;
  final int activeDot;
  final ValueChanged<int> onDot;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  const OnboardingNavRow({
    super.key,
    required this.dotCount,
    required this.activeDot,
    required this.onDot,
    this.onBack,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final back = onBack;
    final next = onNext;
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: back == null
                ? const SizedBox.shrink()
                : OnboardingCircleButton(
                    icon: Icons.arrow_back_ios_rounded,
                    onTap: back,
                  ),
          ),
        ),
        CustomDotIndicator(
          count: dotCount,
          activeIndex: activeDot,
          onTap: onDot,
        ),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: next == null
                ? const SizedBox.shrink()
                : SizedBox(
                    width: _nextWidth,
                    child: QeranButton(
                      label: LocaleKeys.common_next.t(context),
                      onPressed: next,
                      size: QeranButtonSize.md,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
