import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';

/// A slow diagonal band of light that sweeps across a surface, suggesting the
/// premium "glass" of the matchmaker card. Meant to be dropped into a
/// [Positioned.fill] inside an already-clipped [Stack]; it paints only the
/// moving highlight and ignores pointers.
///
/// The sweep plays over the first stretch of each cycle then rests, so it reads
/// as an occasional glint rather than a constant shimmer. Honors reduced-motion:
/// renders nothing when the platform disables animations.
class OnboardingSheen extends StatefulWidget {
  const OnboardingSheen({super.key});

  @override
  State<OnboardingSheen> createState() => _OnboardingSheenState();
}

class _OnboardingSheenState extends State<OnboardingSheen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      if (_c.isAnimating) _c.stop();
      return const SizedBox.shrink();
    }
    if (!_c.isAnimating) _c.repeat();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          // Sweep across the first ~45% of the cycle, then rest off-screen.
          final swept = const Interval(
            0.0,
            0.45,
            curve: Curves.easeInOut,
          ).transform(_c.value);
          final dx = -1.2 + 2.6 * swept;
          return FractionalTranslation(
            translation: Offset(dx, 0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    QeranColors.paper.withValues(alpha: 0),
                    QeranColors.paper.withValues(alpha: 0.22),
                    QeranColors.paper.withValues(alpha: 0),
                  ],
                  stops: const [0.38, 0.5, 0.62],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
