import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Compatibility-score pill for the shared-profile card. [accent] and
/// [textColor] adapt to the bubble it sits in (wine vs paper).
class SharedProfileScoreChip extends StatelessWidget {
  final double percent;
  final Color accent;
  final Color textColor;

  const SharedProfileScoreChip({
    super.key,
    required this.percent,
    required this.accent,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final label = context.tr(
      LocaleKeys.chat_shared_profile_score_label,
      namedArgs: {'percent': '${percent.round()}'},
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: QeranRadii.pill,
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: QeranTypography.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
