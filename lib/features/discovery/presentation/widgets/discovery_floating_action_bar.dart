import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_nav.dart';
import 'package:qeran/core/widgets/bottom_chrome_inset.dart';

import '../blocs/discovery_cubit.dart';
import '../blocs/discovery_state.dart';
import 'discovery_action_bar.dart';
import 'discovery_deck_animation_controller.dart';
import 'discovery_frosted_action_zone.dart';
import 'discovery_like_flow.dart';

/// Inset of the floating action cluster from the card's side edges. The card
/// itself is now full-bleed, so this is the cluster's own margin. Combined
/// with the zone's own 12dp this puts the outer buttons 24dp from the screen
/// edge — half the old 48, so the cluster spreads instead of huddling.
const double _kActionBarHPad = 12.0;

/// Scroll distance over which the action cluster's backdrop fades from
/// invisible to its (already light) peak. Short, because the fold gap gives
/// way at twice the scroll rate — the sections are behind the buttons within
/// the first few tens of pixels.
const double _kFrostRampDistance = 80.0;

/// Floating action bar — anchored to the bottom of the viewport,
/// transparent backdrop, sits over the scrolling profile body. Keeps
/// like / pass / undo reachable from any scroll position. The pill
/// buttons own their own visuals so there's no surrounding white
/// container.
///
/// Stateful so the Like API, heart burst and card eject can overlap safely.
/// Pass, Undo, and horizontal swipe gestures stay immediate. A re-entry flag
/// prevents double-tap stacking during the short sequence.
class DiscoveryFloatingActionBar extends StatefulWidget {
  final DiscoveryState state;
  final void Function(Offset origin) onLikeBurst;
  final ValueNotifier<double> scrollOffset;

  const DiscoveryFloatingActionBar({
    super.key,
    required this.state,
    required this.onLikeBurst,
    required this.scrollOffset,
  });

  @override
  State<DiscoveryFloatingActionBar> createState() =>
      _DiscoveryFloatingActionBarState();
}

class _DiscoveryFloatingActionBarState
    extends State<DiscoveryFloatingActionBar> {
  bool _likePending = false;

  @override
  void dispose() {
    super.dispose();
  }

  /// Starts the Like sequence ([runDiscoveryLikeFlow]) unless one is already
  /// running or the deck is mid-animation.
  void _scheduleLike(DiscoveryDeckAnimationController controller) {
    if (_likePending) return;
    if (controller.isAnimating) return;
    _likePending = true;
    unawaited(
      runDiscoveryLikeFlow(
        cubit: context.read<DiscoveryCubit>(),
        controller: controller,
        isMounted: () => mounted,
        onSettled: () => _likePending = false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DiscoveryCubit>();
    final state = widget.state;
    final loaded = state is DiscoveryLoaded ? state : null;
    final hasActive = loaded != null && !loaded.isEmpty && !loaded.isExhausted;
    final hasUndoTarget = loaded != null && loaded.currentIndex > 0;
    final animController = DeckAnimationScope.of(context);
    // Pin the cluster to the card's bottom edge with extra clearance so it sits cleanly above the bottom-nav island.
    final media = MediaQuery.sizeOf(context);
    final isLandscape = media.width > media.height;
    final navClearance =
        QeranBottomNav.contentClearance(context) + (isLandscape ? 12.0 : 24.0);

    // Enable state derives from the cubit only (see the previous
    // _ActionBarArea note): gating on the animator's busy flag caused
    // a synchronized colour flash across all three buttons. The Like
    // re-entry guard lives inside `_scheduleLike` so the button stays
    // visually enabled during the short wait — rapid taps simply
    // no-op without disabling the press feedback.
    return Positioned(
      left: _kActionBarHPad,
      right: _kActionBarHPad,
      bottom: navClearance + 14.0,
      // The deck stacks a second layer of chrome on top of the nav, so it
      // declares its own (taller) footprint too. The toast host clears the
      // largest live declaration, so on the deck it clears the like/skip row
      // rather than only the nav.
      child: BottomChromeInset(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // At the top the buttons float over the empty paper under نبذة عني,
            // so a backdrop would be pure decoration; it fades in only once
            // profile content is actually passing behind them.
            ValueListenableBuilder<double>(
              valueListenable: widget.scrollOffset,
              builder: (context, offset, child) => DiscoveryFrostedActionZone(
                opacity: (offset / _kFrostRampDistance).clamp(0.0, 1.0),
                child: child!,
              ),
              child: DiscoveryActionBar(
                onPass: hasActive
                    ? () {
                        if (animController.isAnimating) return;
                        unawaited(animController.triggerPass());
                      }
                    : null,
                onUndo: hasUndoTarget
                    ? () {
                        if (animController.isAnimating) return;
                        unawaited(
                          animController.triggerUndo(onUndoCall: cubit.undo),
                        );
                      }
                    : null,
                onLike: hasActive ? () => _scheduleLike(animController) : null,
                onLikeBurst: hasActive
                    ? (origin) {
                        if (animController.isAnimating) return;
                        if (_likePending) return;
                        widget.onLikeBurst(origin);
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
