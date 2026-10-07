import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';

/// A thin determinate progress bar: a gold-40 track filled in gold-deep from
/// the start edge (the right in Arabic). [value] runs from 0 to 1 and is
/// clamped, so a late or rounded report never overflows the track.
class QeranProgressBar extends StatelessWidget {
  const QeranProgressBar({super.key, required this.value});

  final double value;

  static const double height = 4;

  @override
  Widget build(BuildContext context) {
    final fraction = value.clamp(0.0, 1.0);
    return Semantics(
      value: '${(fraction * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: SizedBox(
          height: height,
          child: ColoredBox(
            color: QeranColors.gold40,
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: fraction,
              heightFactor: 1,
              child: const ColoredBox(color: QeranColors.goldDeep),
            ),
          ),
        ),
      ),
    );
  }
}
