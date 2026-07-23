import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/discovery_cubit.dart';
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
    DiscoveryCubit? discoveryCubit() {
      try {
        return BlocProvider.of<DiscoveryCubit>(context, listen: false);
      } catch (_) {
        // Keep the widget a transparent pass-through in isolated fixtures
        // that only provide the animation scope.
        return null;
      }
    }

    bool isLikeInFlight() => discoveryCubit()?.isLikeInFlight ?? false;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: controller == null
          ? null
          : (_) {
              if (isLikeInFlight()) return;
              controller.onDragStart();
            },
      onHorizontalDragUpdate: controller == null
          ? null
          : (details) {
              if (isLikeInFlight()) return;
              controller.onDragUpdate(details.delta.dx);
            },
      onHorizontalDragEnd: controller == null
          ? null
          : (details) {
              if (isLikeInFlight()) return;
              controller.onDragEnd(velocity: details.primaryVelocity ?? 0);
            },
      child: child,
    );
  }
}
