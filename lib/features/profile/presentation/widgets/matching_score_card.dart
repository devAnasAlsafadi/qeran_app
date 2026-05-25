import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Inline "{n}% compatibility" pill rendered above the placements on
/// the other-profile screen. Hidden when [percent] is 0 (server's
/// "not scored" sentinel).
class MatchingScoreCard extends StatelessWidget {
  final double percent;
  const MatchingScoreCard({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    if (percent <= 0) return const SizedBox.shrink();
    final rounded = percent.round();
    final label = context.tr(
      LocaleKeys.profile_compatibility_label,
      namedArgs: {'percent': '$rounded'},
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s20,
        vertical: QeranSpacing.s8,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: QeranChip(
          label: label,
          variant: QeranChipVariant.score,
          icon: Icons.favorite_rounded,
        ),
      ),
    );
  }
}
