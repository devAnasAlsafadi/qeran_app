import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_motion.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

/// The content-screen page dots — one per non-splash frame. The active dot is a
/// gold pill (22px); the rest are faint gold dots (7px). Tapping a dot jumps to
/// that frame via [onTap] (index `0..count-1` → wizard step `1..count`).
///
/// The dots ride the wine canvas, so the inactive fill is [QeranColors.gold40];
/// the wine wash they used to carry would be invisible against it.
///
/// Each dot paints 7px tall but is tappable across [_hitHeight] — a 7px target
/// is far under the 48dp floor, and a finger arriving from below needs the
/// vertical room. The horizontal extent is deliberately left alone: padding it
/// to 48 too would push the dots ~3× further apart and redraw the row for an
/// affordance that is secondary to swiping and the nav buttons.
///
/// Direction-agnostic: it's a plain `Row`, so it mirrors automatically in RTL.
class CustomDotIndicator extends StatelessWidget {
  /// Vertical tap target per dot. The painted dot stays 7px and centred.
  static const double _hitHeight = 48;

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
            child: SizedBox(
              height: _hitHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: QeranSpacing.s4,
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: QeranMotion.standard,
                    curve: QeranCurves.standard,
                    width: i == activeIndex ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == activeIndex
                          ? QeranColors.gold
                          : QeranColors.gold40,
                      borderRadius: QeranRadii.pill,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
