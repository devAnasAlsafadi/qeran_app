import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_motion.dart';

/// Dual-arc spinner inspired by the ring monogram.
/// Replaces every [CircularProgressIndicator] in the app.
class QeranLoader extends StatefulWidget {
  const QeranLoader({
    super.key,
    this.size = 36,
    this.strokeWidth = 2.4,
    this.primary = QeranColors.wine,
    this.accent = QeranColors.gold,
  });

  /// Small variant for inline use (inside buttons).
  ///
  /// When [color] is provided, both arcs render in that colour so the loader
  /// stays visible on any button variant (wine on gold, white on wine, etc.).
  const QeranLoader.inline({super.key, Color? color})
      : size = 18,
        strokeWidth = 2.2,
        primary = color ?? QeranColors.wine,
        accent = color ?? QeranColors.gold;

  final double size;
  final double strokeWidth;
  final Color primary;
  final Color accent;

  @override
  State<QeranLoader> createState() => _QeranLoaderState();
}

class _QeranLoaderState extends State<QeranLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: QeranMotion.loaderCycle)
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: _DualArcPainter(
            t: _c.value,
            primary: widget.primary,
            accent: widget.accent,
            stroke: widget.strokeWidth,
          ),
        ),
      ),
    );
  }
}

class _DualArcPainter extends CustomPainter {
  _DualArcPainter({
    required this.t,
    required this.primary,
    required this.accent,
    required this.stroke,
  });

  final double t;
  final Color primary;
  final Color accent;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide / 2 - stroke;
    final base = Rect.fromCircle(center: center, radius: radius);

    final paintPrimary = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = primary;

    final paintAccent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = accent;

    final rot = t * 2 * math.pi;
    const sweep = math.pi * 0.95;

    canvas.drawArc(base, rot, sweep, false, paintPrimary);
    canvas.drawArc(base, rot + math.pi, sweep, false, paintAccent);
  }

  @override
  bool shouldRepaint(covariant _DualArcPainter old) =>
      old.t != t ||
      old.primary != primary ||
      old.accent != accent ||
      old.stroke != stroke;
}
