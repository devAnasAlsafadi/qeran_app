import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';

import '../blocs/discovery_cubit.dart';
import '../blocs/discovery_hydration_cubit.dart';
import '../blocs/discovery_state.dart';
import 'discovery_card_skeleton.dart';
import 'discovery_deck_animation_controller.dart';
import 'discovery_feedback.dart';
import 'discovery_floating_action_bar.dart';
import 'discovery_filter_hint_dialog.dart';
import 'discovery_like_burst.dart';
import 'discovery_state_body.dart';
import 'discovery_unified_card.dart';

/// Reusable Discovery content. Self-contained — provides its own
/// `DiscoveryCubit` and drives `loadInitial` on first build.
///
/// Layout: ONE scroll per card. The photo runs edge to edge horizontally and
/// takes the top half of the viewport, starting just BELOW the status bar;
/// scrolling reveals the whole profile inline (there is no separate Full
/// Profile screen to tap through to any more). The like / skip / undo cluster
/// is pinned above the nav and stays reachable at every scroll offset, its
/// backdrop fading in only once content is behind it. Horizontal drags run the
/// existing swipe flow, gated on being scrolled to the top.
class DiscoveryView extends StatelessWidget {
  const DiscoveryView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DiscoveryCubit>(
          create: (_) => sl<DiscoveryCubit>()..loadInitial(),
        ),
        // Below-the-fold profile hydration, cached per profile id. Separate
        // from DiscoveryCubit so a hydrate failure can never touch the deck,
        // its pagination, or the paywall / daily-limit gating.
        BlocProvider<DiscoveryHydrationCubit>(
          create: (_) => sl<DiscoveryHydrationCubit>(),
        ),
      ],
      child: const _DiscoveryContent(),
    );
  }
}

class _DiscoveryContent extends StatefulWidget {
  const _DiscoveryContent();

  @override
  State<_DiscoveryContent> createState() => _DiscoveryContentState();
}

/// True when [state] renders a full-screen replacement that owns the
/// whole feed area — the daily-view limit screen, the load-failure
/// state, or the terminal empty view. In these states the floating
/// like / pass / undo cluster has no live deck to act on and must NOT
/// paint over the replacement content (it otherwise leaks through as a
/// disabled cluster — see `DiscoveryActionBar`, which doesn't self-hide
/// on null callbacks).
///
/// Loading and the transient prefetch-loader (`hasMore`) are deliberately
/// excluded: the deck is arriving, so the bar stays (disabled) to avoid a
/// blink-out/blink-in during a fast swipe-to-end.
bool _isFullScreenReplacement(DiscoveryState state) {
  if (state is DiscoveryDailyLimit || state is DiscoveryFailure) return true;
  if (state is DiscoveryLoaded) {
    if (!state.isEmpty && !state.isExhausted) return false;
    // A deck with nothing to show and a failed prefetch is terminal until the
    // user retries, so the error surface owns the screen exactly as
    // DiscoveryFailure does. Without the second clause the action cluster
    // floats over it — its controls dead (`current` is null) and its frosted
    // zone covering the retry button.
    return !state.hasMore || state.prefetchError != null;
  }
  return false;
}

class _DiscoveryContentState extends State<_DiscoveryContent> {
  late final DiscoveryDeckAnimationController _animController =
      DiscoveryDeckAnimationController();

  /// Prevents stacking multiple flying hearts when the user mashes
  /// Like. The first heart's `onComplete` clears this so the next tap
  /// can spawn again. Independent from `_animController.isAnimating`
  /// because hearts can outlive the controller's busy window.
  bool _likeBurstInFlight = false;
  bool _filterHintCheckStarted = false;

  /// Current card's scroll offset, published by [DiscoveryUnifiedCard].
  ///
  /// Lives here, above both, because the card owns the scroll while the action
  /// cluster — a sibling in the screen-level Stack — needs the same value to
  /// decide whether to draw a backdrop. A notifier rather than state so a
  /// scroll repaints only the cluster's backdrop, never the blurred photo.
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _animController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  /// Inserts a self-removing OverlayEntry that flies a burgundy heart
  /// from [origin] to the card's image-area center. No-op if a heart
  /// is already in flight or there's no Overlay available.
  void _spawnLikeBurst(Offset origin) {
    if (_likeBurstInFlight) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    // The photo's centre; the photo starts at the top of this area.
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final size = box.size;
    final photoHeight = discoveryPhotoHeight(
      context,
      viewportHeight: size.height,
      isLandscape: size.width > size.height,
    );
    final target = box.localToGlobal(Offset(size.width / 2, photoHeight / 2));

    _likeBurstInFlight = true;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => DiscoveryLikeBurst(
        origin: origin,
        target: target,
        onComplete: () {
          if (entry.mounted) entry.remove();
          _likeBurstInFlight = false;
        },
      ),
    );
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return DeckAnimationScope(
      notifier: _animController,
      child: BlocConsumer<DiscoveryCubit, DiscoveryState>(
        listenWhen: discoveryFeedbackListenWhen,
        listener: (context, state) {
          if (state is! DiscoveryLoaded) return;
          if (state.current != null) {
            unawaited(_maybeShowFilterHint());
          }
          showDiscoveryFeedback(context, state, _animController);
        },
        builder: (context, state) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: _buildBody(context, state)),
              if (!_isFullScreenReplacement(state))
                DiscoveryFloatingActionBar(
                  state: state,
                  onLikeBurst: _spawnLikeBurst,
                  scrollOffset: _scrollOffset,
                ),
            ],
          );
        },
      ),
    );
  }

  /// The photo starts below the shell's top bar, which owns the status-bar
  /// inset; the SafeArea keeps the sides clear of a landscape notch. The
  /// title row sits on the photo itself, not in a bar above it.
  Widget _buildBody(BuildContext context, DiscoveryState state) => SafeArea(
    bottom: false,
    child: DiscoveryStateBody(state: state, scrollOffset: _scrollOffset),
  );

  Future<void> _maybeShowFilterHint() async {
    if (_filterHintCheckStarted) return;
    _filterHintCheckStarted = true;
    if (!sl.isRegistered<UserSessionCubit>() ||
        !sl.isRegistered<SharedPrefService>()) {
      return;
    }
    final userId = sl<UserSessionCubit>().currentUser?.id.trim() ?? '';
    if (userId.isEmpty) return;
    final key = 'discovery_filter_hint_seen_v1_$userId';
    final prefs = sl<SharedPrefService>();
    final seen = await prefs.get<bool>(key) ?? false;
    if (seen || !mounted) return;
    await prefs.save<bool>(key, true);
    if (!mounted) return;
    await showDiscoveryFilterHintDialog(context);
  }
}
