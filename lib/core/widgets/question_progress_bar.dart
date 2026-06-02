import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';

class QuestionProgressBar extends StatelessWidget {
  /// Value between 0.0 and 1.0.
  final double progress;

  const QuestionProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: QeranRadii.pill,
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 5,
        backgroundColor: QeranColors.wine12,
        valueColor: const AlwaysStoppedAnimation<Color>(QeranColors.wine),
      ),
    );
  }
}
