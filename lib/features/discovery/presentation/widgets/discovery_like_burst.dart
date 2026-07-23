import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';

/// Gold heart that flies from the Like button to the card image area
/// in two stages and fades into the card-level Like overlay. Gold so
/// it visually originates from the gold heart inside the wine Like
/// circle (the icon "lifts off" without changing colour).
///
/// Stage 1 (travel) — 0 → 380 ms: heart appears at the button center
/// at full opacity / scale 1.0, then arcs upward toward the target,
/// peaking ~44 px above the straight line at midpoint and growing to
/// 1.20. No birth/spawn animation — feels faster and cleaner.
/// Stage 2 (settle + fade) — 380 → 480 ms: settles to 1.00 while
/// fading out into the card-level Like overlay.
///
/// Self-contained: owns its `AnimationController`, calls `onComplete`
/// when done, disposes in `dispose()`. `IgnorePointer` keeps the heart
/// transparent to touch.
class DiscoveryLikeBurst extends StatefulWidget {
  final Offset origin;
  final Offset target;
  final VoidCallback onComplete;

  const DiscoveryLikeBurst({
    super.key,
    required this.origin,
    required this.target,
    required this.onComplete,
  });

  @override
  State<DiscoveryLikeBurst> createState() => _DiscoveryLikeBurstState();
}

class _DiscoveryLikeBurstState extends State<DiscoveryLikeBurst>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 480);

  /// End of travel stage / start of fade.
  static const double _travelEnd = 380 / 480;

  static const double _arcHeight = 44.0;
  static const double _iconSize = 56.0;

  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _duration);

    // Scale (weights are ms — TweenSequence normalises):
    //   0   → 380 ms  1.00 → 1.20  (grow during travel)
    //   380 → 480 ms  1.20 → 1.00  (settle)
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.00,
          end: 1.20,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 380,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.20,
          end: 1.00,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 100,
      ),
    ]).animate(_ctrl);

    // Opacity:
    //   0   → 380 ms  hold 1   (fully opaque through travel)
    //   380 → 480 ms  1 → 0    (fade into card overlay)
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 380),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 100,
      ),
    ]).animate(_ctrl);

    _ctrl.forward().whenComplete(() {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Position at timeline `t` (0→1).
  /// Stage 1: arcs from origin to target (easeInOutCubic + sine bow).
  /// Stage 2: holds at target while fade completes.
  Offset _positionAt(double t) {
    if (t <= _travelEnd) {
      final s = Curves.easeInOutCubic.transform(t / _travelEnd);
      final dx = lerpDouble(widget.origin.dx, widget.target.dx, s)!;
      final linearY = lerpDouble(widget.origin.dy, widget.target.dy, s)!;
      final arc = -_arcHeight * math.sin(math.pi * s);
      return Offset(dx, linearY + arc);
    }
    return widget.target;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final pos = _positionAt(_ctrl.value);
        return Positioned(
          left: pos.dx - _iconSize / 2,
          top: pos.dy - _iconSize / 2,
          child: IgnorePointer(
            child: Opacity(
              opacity: _opacity.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: _scale.value,
                child: const Icon(
                  Icons.favorite_rounded,
                  size: _iconSize,
                  color: QeranColors.gold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
