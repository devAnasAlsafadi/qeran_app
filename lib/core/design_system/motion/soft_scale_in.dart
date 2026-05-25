import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens/qeran_motion.dart';

/// Signature Qeran entry: soft scale (0.94 → 1.0) + fade (0 → 1).
/// Used on hero surfaces (splash, match-success, paywall hero,
/// profile-details first paint).
class SoftScaleIn extends StatefulWidget {
  const SoftScaleIn({
    super.key,
    required this.child,
    this.duration = QeranMotion.hero,
    this.curve = QeranCurves.hero,
    this.delay = Duration.zero,
    this.beginScale = 0.94,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final Duration delay;
  final double beginScale;

  @override
  State<SoftScaleIn> createState() => _SoftScaleInState();
}

class _SoftScaleInState extends State<SoftScaleIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _delay = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(parent: _c, curve: widget.curve);
    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) {
        final t = anim.value;
        final scale = widget.beginScale + (1.0 - widget.beginScale) * t;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: widget.child,
    );
  }
}
