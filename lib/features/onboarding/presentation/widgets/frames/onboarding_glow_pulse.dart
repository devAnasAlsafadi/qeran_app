import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';

/// A slow, breathing gold halo behind [child] — the aspirational glow used on
/// the journey's destination node and the primary CTA. The halo eases in and
/// out between a dim and a bright state; an optional [scaleAmount] adds a faint
/// swell in sympathy with it.
///
/// Honors reduced-motion: when the platform disables animations it renders a
/// soft *static* glow (the aspiration still reads) with no controller running.
class OnboardingGlowPulse extends StatefulWidget {
  final Widget child;

  /// Peak blur of the halo, in logical pixels.
  final double maxBlur;

  /// Peak spread of the halo, in logical pixels.
  final double maxSpread;

  /// Peak extra scale at the top of the breath (0 = no swell).
  final double scaleAmount;

  /// Shape the halo to a rounded rectangle. Ignored when [circle] is true.
  final BorderRadius? borderRadius;

  /// Shape the halo to a circle (for round nodes).
  final bool circle;

  const OnboardingGlowPulse({
    super.key,
    required this.child,
    this.maxBlur = 22,
    this.maxSpread = 2,
    this.scaleAmount = 0,
    this.borderRadius,
    this.circle = false,
  });

  @override
  State<OnboardingGlowPulse> createState() => _OnboardingGlowPulseState();
}

class _OnboardingGlowPulseState extends State<OnboardingGlowPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _decorated(double t, {Widget? child}) {
    final glow = DecoratedBox(
      decoration: BoxDecoration(
        shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.circle ? null : widget.borderRadius,
        boxShadow: [
          BoxShadow(
            color: QeranColors.gold.withValues(alpha: 0.16 + 0.30 * t),
            blurRadius: widget.maxBlur * (0.5 + 0.5 * t),
            spreadRadius: widget.maxSpread * t,
          ),
        ],
      ),
      child: child ?? widget.child,
    );
    if (widget.scaleAmount == 0) return glow;
    return Transform.scale(scale: 1.0 + widget.scaleAmount * t, child: glow);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      if (_c.isAnimating) _c.stop();
      return _decorated(0.55); // gentle static halo
    }
    if (!_c.isAnimating) _c.repeat(reverse: true);
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) =>
          _decorated(Curves.easeInOut.transform(_c.value), child: child),
    );
  }
}
