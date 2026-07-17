import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';

/// The "days remaining" ring on the My-subscription card: a soft wine track with
/// a rounded [arcColor] progress arc sweeping clockwise from the top. [arcColor]
/// defaults to gold and turns danger-toned for the expiring-soon state.
class DaysRemainingPainter extends CustomPainter {
  /// Fraction of the subscription period still remaining, in `[0, 1]`.
  final double progress;
  final Color arcColor;

  const DaysRemainingPainter({
    required this.progress,
    this.arcColor = QeranColors.gold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    const strokeWidth = 7.0;

    // Wine hairline track (legible on the paper/cream card, unlike a white one).
    final bgPaint = Paint()
      ..color = QeranColors.wine08
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final fgPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Progress arc, starting from the top (-pi/2), clockwise.
    final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant DaysRemainingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.arcColor != arcColor;
  }
}
