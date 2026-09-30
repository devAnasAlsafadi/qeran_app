import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

/// A dashed outline drawn around its child — a circle by default, or a
/// rounded rectangle when [borderRadius] is set.
///
/// It marks a place that is reserved but not filled yet: the matchmaker
/// avatar while one is still being assigned, a surface whose content arrives
/// later. A solid ring says "here it is"; a dashed one says "coming".
///
/// The stroke sits inside the box, like a CSS border, so it never changes
/// the child's layout. Dashes are spread evenly around the outline, so a
/// closed shape never ends in a clipped half-dash at the seam.
class QeranDashedRing extends StatelessWidget {
  const QeranDashedRing({
    super.key,
    required this.color,
    this.borderRadius,
    this.strokeWidth = 1.5,
    this.child,
  });

  final Color color;

  /// Null → a circle (an oval if the box isn't square).
  final BorderRadius? borderRadius;

  final double strokeWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedOutlinePainter(
        color: color,
        borderRadius: borderRadius,
        strokeWidth: strokeWidth,
      ),
      child: child,
    );
  }
}

class _DashedOutlinePainter extends CustomPainter {
  _DashedOutlinePainter({
    required this.color,
    required this.borderRadius,
    required this.strokeWidth,
  });

  final Color color;
  final BorderRadius? borderRadius;
  final double strokeWidth;

  // A thin CSS dashed border's proportions: the dash three strokes long, the
  // gap two, so the rhythm scales with the stroke.
  double get _dash => strokeWidth * 3;
  double get _gap => strokeWidth * 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    for (final metric in _outline(size).computeMetrics()) {
      canvas.drawPath(_dashesAlong(metric), paint);
    }
  }

  /// The outline's centre line, half a stroke in from the box edge.
  Path _outline(Size size) {
    final box = Offset.zero & size;
    final inset = strokeWidth / 2;
    final radius = borderRadius;
    if (radius == null) return Path()..addOval(box.deflate(inset));
    return Path()..addRRect(radius.toRRect(box).deflate(inset));
  }

  Path _dashesAlong(PathMetric metric) {
    final period = _dash + _gap;
    final count = math.max(1, (metric.length / period).round());
    final step = metric.length / count;
    final dash = step * _dash / period;
    final dashes = Path();
    for (var i = 0; i < count; i++) {
      final start = i * step;
      dashes.addPath(metric.extractPath(start, start + dash), Offset.zero);
    }
    return dashes;
  }

  @override
  bool shouldRepaint(covariant _DashedOutlinePainter old) =>
      old.color != color ||
      old.borderRadius != borderRadius ||
      old.strokeWidth != strokeWidth;
}
