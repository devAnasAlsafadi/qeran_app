import 'package:flutter/foundation.dart';
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
class DiscoverySwipeHandler extends StatefulWidget {
  final Widget child;

  /// Gates the horizontal drag. The merged screen passes the card's
  /// "scrolled to the top" flag: once the user has scrolled down into the
  /// profile, a near-horizontal drag is far more likely to be a clumsy scroll
  /// than a deliberate swipe, and ejecting the card out from under someone
  /// mid-read is unrecoverable. The action buttons stay live at every offset,
  /// so nothing becomes unreachable.
  ///
  /// Read ONCE per gesture, at drag start, and latched for that gesture — a
  /// swipe begun at the top runs to completion even though the card moves.
  ///
  /// Null (default) means always enabled — the behaviour every existing
  /// fixture and the legacy card relied on.
  final ValueListenable<bool>? enabled;

  const DiscoverySwipeHandler({super.key, required this.child, this.enabled});

  @override
  State<DiscoverySwipeHandler> createState() => _DiscoverySwipeHandlerState();
}

class _DiscoverySwipeHandlerState extends State<DiscoverySwipeHandler> {
  /// Latched at drag start from [DiscoverySwipeHandler.enabled].
  bool _allowedThisGesture = true;

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

    // The GestureDetector is ALWAYS mounted, even while the gate is closed,
    // and the gate is applied inside the callbacks instead. Swapping the
    // detector in and out of the tree would tear down its render object in
    // the middle of a live pointer sequence — which cancels the whole arena
    // entry, so the vertical scroll that closed the gate would itself die on
    // its first frame.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: controller == null
          ? null
          : (_) {
              _allowedThisGesture = widget.enabled?.value ?? true;
              if (!_allowedThisGesture) return;
              if (isLikeInFlight()) return;
              controller.onDragStart();
            },
      onHorizontalDragUpdate: controller == null
          ? null
          : (details) {
              if (!_allowedThisGesture) return;
              if (isLikeInFlight()) return;
              controller.onDragUpdate(details.delta.dx);
            },
      onHorizontalDragEnd: controller == null
          ? null
          : (details) {
              if (!_allowedThisGesture) return;
              if (isLikeInFlight()) return;
              controller.onDragEnd(velocity: details.primaryVelocity ?? 0);
            },
      child: widget.child,
    );
  }
}
