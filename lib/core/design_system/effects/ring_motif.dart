import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';

/// Decorative thin ring outlines derived from the identity's circle
/// motif. Used as a quiet flourish on hero surfaces (paywall, match
/// success, splash, profile-details header).
///
/// Pure painter — no animation, no asset, low-cost. Place behind hero
/// content via `Stack` + `Positioned` and let the focal element sit on
/// top.
class RingMotif extends StatelessWidget {
  const RingMotif({
    super.key,
    this.color = QeranColors.gold,
    this.opacity = 0.08,
    this.stroke = 1.2,
    this.size = 220,
    this.ringCount = 2,
    this.spacing = 14,
  });

  /// Base ring colour. Alpha is applied via [opacity].
  final Color color;

  /// 0..1 alpha for the rings. Identity guidance: 6–10%.
  final double opacity;

  /// Stroke width for each ring.
  final double stroke;

  /// Outermost ring diameter.
  final double size;

  /// Number of concentric rings.
  final int ringCount;

  /// Distance between concentric rings.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingMotifPainter(
            color: color.withValues(alpha: opacity),
            stroke: stroke,
            ringCount: ringCount,
            spacing: spacing,
          ),
        ),
      ),
    );
  }
}

class _RingMotifPainter extends CustomPainter {
  _RingMotifPainter({
    required this.color,
    required this.stroke,
    required this.ringCount,
    required this.spacing,
  });

  final Color color;
  final double stroke;
  final int ringCount;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color;
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide / 2 - stroke;

    for (var i = 0; i < ringCount; i++) {
      final r = maxRadius - i * spacing;
      if (r <= 0) break;
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingMotifPainter old) =>
      old.color != color ||
      old.stroke != stroke ||
      old.ringCount != ringCount ||
      old.spacing != spacing;
}
