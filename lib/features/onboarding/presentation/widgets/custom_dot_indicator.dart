import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_motion.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

/// The content-screen page dots — one per non-splash frame. The active dot is a
/// gold pill (22px); the rest are small wine dots (7px). Tapping a dot jumps to
/// that frame via [onTap] (index `0..count-1` → wizard step `1..count`).
///
/// Direction-agnostic: it's a plain `Row`, so it mirrors automatically in RTL.
class CustomDotIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;
  final ValueChanged<int> onTap;

  const CustomDotIndicator({
    super.key,
    required this.count,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s4),
              child: AnimatedContainer(
                duration: QeranMotion.standard,
                curve: QeranCurves.standard,
                width: i == activeIndex ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == activeIndex
                      ? QeranColors.gold
                      : QeranColors.wine20,
                  borderRadius: QeranRadii.pill,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
