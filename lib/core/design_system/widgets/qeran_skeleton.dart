import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_motion.dart';
import '../tokens/qeran_radii.dart';

/// Warm-cream skeleton with a gold shimmer pass. Never grey.
class QeranSkeleton extends StatefulWidget {
  const QeranSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius,
  });

  /// Circle skeleton — for avatars, icons.
  const QeranSkeleton.circle({super.key, required double size})
      : width = size,
        height = size,
        radius = null;

  /// Rectangle / card skeleton.
  const QeranSkeleton.box({
    super.key,
    this.width,
    required this.height,
    this.radius = QeranRadii.card,
  });

  final double? width;
  final double height;
  final double? radius;

  @override
  State<QeranSkeleton> createState() => _QeranSkeletonState();
}

class _QeranSkeletonState extends State<QeranSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: QeranMotion.shimmer)
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  bool get _isCircle => widget.radius == null && widget.width == widget.height;

  @override
  Widget build(BuildContext context) {
    final borderRadius = _isCircle
        ? BorderRadius.circular(widget.height)
        : BorderRadius.circular(widget.radius ?? 8);

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(
            painter: _ShimmerPainter(progress: _c.value),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = QeranColors.creamSurface;
    canvas.drawRect(Offset.zero & size, base);

    final dx = (progress * 2 - 1) * size.width;
    final shimmer = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [
          Color(0x00E4C094),
          Color(0x2EE4C094),
          Color(0x00E4C094),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromLTWH(dx, 0, size.width, size.height),
      );

    canvas.drawRect(
      Rect.fromLTWH(dx, 0, size.width, size.height),
      shimmer,
    );
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter old) =>
      old.progress != progress;
}
