import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(QeranRadii.control),
    );

    Path path = Path()..addRRect(rrect);
    Path dashedPath = _createDashedPath(path, gap);
    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(Path source, double gap) {
    PathMetrics pathMetrics = source.computeMetrics();
    Path dest = Path();
    for (PathMetric metric in pathMetrics) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        double len = draw ? gap : gap;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
