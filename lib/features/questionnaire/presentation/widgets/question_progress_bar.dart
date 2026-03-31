import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';

class QuestionProgressBar extends StatelessWidget {
  /// Value between 0.0 and 1.0.
  final double progress;

  const QuestionProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 5,
        backgroundColor: AppColors.border,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }
}
