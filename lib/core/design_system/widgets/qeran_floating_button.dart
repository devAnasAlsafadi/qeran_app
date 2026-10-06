import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_radii.dart';
import '../tokens/qeran_shadows.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';

/// The one action a list screen floats over its content — «منشور جديد» on
/// her Community screen: a gold pill with an icon and a label, raised (e3),
/// at the screen's end. The caller places it (a Scaffold's floating slot)
/// and keeps [clearance] free under the list's last item.
class QeranFloatingButton extends StatelessWidget {
  const QeranFloatingButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  static const double height = 56;

  /// The room a list keeps under its last item so the button never covers
  /// it: the button, its margin above the safe area, and the safe area.
  static double clearance(BuildContext context) =>
      height + QeranSpacing.s32 + MediaQuery.paddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: QeranRadii.pill,
          boxShadow: QeranShadows.e3,
        ),
        child: Material(
          color: QeranColors.gold,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onPressed, child: _content()),
        ),
      ),
    );
  }

  Widget _content() => SizedBox(
    height: height,
    child: Padding(
      padding: const EdgeInsetsDirectional.only(
        start: QeranSpacing.s16,
        end: QeranSpacing.s20,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: QeranColors.wine),
          const SizedBox(width: QeranSpacing.s8),
          Text(
            label,
            style: QeranTypography.body.copyWith(
              color: QeranColors.wine,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}
