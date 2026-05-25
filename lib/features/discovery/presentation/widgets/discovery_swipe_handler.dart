import 'package:flutter/material.dart';

import 'discovery_deck_animation_controller.dart';

/// Translates raw horizontal-drag gestures on the Discovery card into
/// calls on the surrounding [DeckAnimationScope]'s controller.
///
/// All decision-making (live offset tracking, snap-back vs eject, cubit
/// commit) lives in `DiscoveryDeckAnimator`. This widget is just the
/// gesture adapter — the public surface intentionally takes only a
/// child so there is one path from gesture → controller → animator →
/// cubit (button taps share the same animator).
///
/// If no [DeckAnimationScope] is present in the tree the gesture
/// callbacks are null, making the handler a transparent pass-through.
/// That mode is only reached in widget tests; production always wraps
/// the swipe handler in a scope.
class DiscoverySwipeHandler extends StatelessWidget {
  final Widget child;

  const DiscoverySwipeHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final controller = DeckAnimationScope.maybeOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: controller == null
          ? null
          : (_) => controller.onDragStart(),
      onHorizontalDragUpdate: controller == null
          ? null
          : (details) => controller.onDragUpdate(details.delta.dx),
      onHorizontalDragEnd: controller == null
          ? null
          : (details) =>
              controller.onDragEnd(velocity: details.primaryVelocity ?? 0),
      child: child,
    );
  }
}
