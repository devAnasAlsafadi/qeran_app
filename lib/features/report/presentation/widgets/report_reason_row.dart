import 'package:flutter/material.dart';

import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_motion.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

/// A DS radio row — a 20×20 circle that fills gold with a wine dot when
/// selected, leading the reason label. The whole row is tappable.
class ReportReasonRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const ReportReasonRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: QeranRadii.xsR,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _Dot(selected: selected),
            QeranSpacing.hs12,
            Expanded(
              child: Text(
                label,
                style: QeranTypography.body.copyWith(
                  color: selected ? QeranColors.wine : QeranColors.inkBody,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The radio itself: a wine-40 ring, or a gold disc with a wine dot.
class _Dot extends StatelessWidget {
  const _Dot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: QeranMotion.fast,
      curve: QeranCurves.standard,
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? QeranColors.gold : null,
        border: selected
            ? null
            : Border.all(color: QeranColors.wine40, width: 1.5),
      ),
      child: selected
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: QeranColors.wine,
              ),
            )
          : null,
    );
  }
}
