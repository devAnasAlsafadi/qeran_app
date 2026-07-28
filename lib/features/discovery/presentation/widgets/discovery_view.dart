import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_nav.dart';
import 'package:qeran/core/design_system/widgets/qeran_error_state.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/notifications/presentation/blocs/notification_badge_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/paywall/paywall_bottom_sheet.dart';
import 'package:qeran/features/subscriptions/presentation/paywall/paywall_intent.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/discovery_profile.dart';
import '../../domain/entities/like_outcome.dart';
import '../blocs/discovery_cubit.dart';
import '../blocs/discovery_hydration_cubit.dart';
import '../blocs/discovery_state.dart';
import '../screens/discovery_filter_sheet.dart';
import 'discovery_action_bar.dart';
import 'discovery_blurred_image.dart';
import 'discovery_card_skeleton.dart';
import 'discovery_deck_animation_controller.dart';
import 'discovery_daily_limit_view.dart';
import 'discovery_empty_view.dart';
import 'discovery_frosted_action_zone.dart';
import 'discovery_like_burst.dart';
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
        // App-wide unread-badge singleton (refreshed in initState + on resume,
        // not per build). `.value` so the shared singleton is never closed here.
        BlocProvider<NotificationBadgeCubit>.value(
          value: sl<NotificationBadgeCubit>(),
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

// ── Design constants ────────────────────────────────────────────────────────

/// Inset of the floating action cluster from the card's side edges. The card
/// itself is now full-bleed, so this is the cluster's own margin. Combined
/// with the zone's own 12dp this puts the outer buttons 24dp from the screen
/// edge — half the old 48, so the cluster spreads instead of huddling.
const double _kActionBarHPad = 12.0;

/// Height reserved at the end of the scroll so the last section and the share
/// CTA can travel clear of the pinned frosted action cluster.
const double _kActionZoneClearance = 128.0;

/// Scroll distance over which the action cluster's backdrop fades from
/// invisible to its (already light) peak. Short, because the fold gap gives
/// way at twice the scroll rate — the sections are behind the buttons within
/// the first few tens of pixels.
const double _kFrostRampDistance = 80.0;

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
    return (state.isEmpty || state.isExhausted) && !state.hasMore;
  }
  return false;
}

class _DiscoveryContentState extends State<_DiscoveryContent>
    with WidgetsBindingObserver {
  late final DiscoveryDeckAnimationController _animController =
      DiscoveryDeckAnimationController();

  /// Prevents stacking multiple flying hearts when the user mashes
  /// Like. The first heart's `onComplete` clears this so the next tap
  /// can spawn again. Independent from `_animController.isAnimating`
  /// because hearts can outlive the controller's busy window.
  bool _likeBurstInFlight = false;

  /// Current card's scroll offset, published by [DiscoveryUnifiedCard].
  ///
  /// Lives here, above both, because the card owns the scroll while the action
  /// cluster — a sibling in the screen-level Stack — needs the same value to
  /// decide whether to draw a backdrop. A notifier rather than state so a
  /// scroll repaints only the cluster's backdrop, never the blurred photo.
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // First unread check on mount (app open / return to the discovery tab).
    sl<NotificationBadgeCubit>().refresh();
  }

  /// Re-check the unread badge when the app returns to the foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      sl<NotificationBadgeCubit>().refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    final screen = MediaQuery.of(context).size;
    final target = Offset(screen.width / 2, screen.height * 0.22);

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
        listenWhen: (prev, curr) {
          if (curr is! DiscoveryLoaded || curr.actionFailureKind == null) {
            return false;
          }
          if (prev is! DiscoveryLoaded) return true;
          return prev.actionErrorVersion != curr.actionErrorVersion;
        },
        listener: (context, state) {
          if (state is! DiscoveryLoaded) return;
          final kind = state.actionFailureKind;
          if (kind == null) return;
          // Typed dispatch — the cubit has already classified the
          // server's response into one of the five LikeFailureKind
          // variants. The old heuristic (no subscription OR likes
          // remaining == 0) is gone; the server is the source of truth.
          //
          // For the two "no-advance" failures (paywall / network) we
          // also fire `triggerSnapBack` so a swipe-driven attempt that
          // already animated the card off-screen doesn't leave the
          // deck blank. Button-driven failures never ran the eject, so
          // the snap-back call is a no-op there.
          switch (kind) {
            case LikeFailureKind.paywall:
              unawaited(_animController.triggerSnapBack());
              showPaywall(context, intent: PaywallIntent.like);
            case LikeFailureKind.alreadyPending:
              AppSnackBar.show(
                context,
                message: LocaleKeys.discovery_like_already_pending.t(context),
                type: SnackBarType.info,
              );
            case LikeFailureKind.genderMismatch:
              AppSnackBar.show(
                context,
                message: LocaleKeys.discovery_like_gender_mismatch.t(context),
                type: SnackBarType.error,
              );
            case LikeFailureKind.userUnavailable:
              AppSnackBar.show(
                context,
                message: LocaleKeys.discovery_like_user_unavailable.t(context),
                type: SnackBarType.info,
              );
            case LikeFailureKind.underReview:
              unawaited(_animController.triggerSnapBack());
              AppSnackBar.show(
                context,
                message: LocaleKeys.profile_status_pending_review.t(context),
                type: SnackBarType.info,
              );
            case LikeFailureKind.network:
              unawaited(_animController.triggerSnapBack());
              AppSnackBar.show(
                context,
                message: LocaleKeys.errors_generic.t(context),
                type: SnackBarType.error,
              );
            case LikeFailureKind.offline:
              unawaited(_animController.triggerSnapBack());
              AppSnackBar.show(
                context,
                message: LocaleKeys.errors_offline.t(context),
                type: SnackBarType.error,
              );
          }
        },
        builder: (context, state) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: _buildBody(context, state)),
              if (!_isFullScreenReplacement(state))
                _FloatingActionBar(
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

  /// The status bar stays opaque and the photo starts BELOW it — hence the
  /// top SafeArea here rather than inside the card. No title bar: the two
  /// overlay buttons float on the photo itself.
  Widget _buildBody(BuildContext context, DiscoveryState state) => SafeArea(
    bottom: false,
    child: _ScrollableProfile(state: state, scrollOffset: _scrollOffset),
  );
}

/// Owns the pull-to-refresh + the state switch below the top bar. Loading /
/// failure / empty states use always-scrollable containers so
/// `RefreshIndicator` keeps working; the loaded state renders [_ProfilePage]
/// (a fixed card whose data region scrolls internally).
class _ScrollableProfile extends StatelessWidget {
  final DiscoveryState state;
  final ValueNotifier<double> scrollOffset;
  const _ScrollableProfile({required this.state, required this.scrollOffset});

  @override
  Widget build(BuildContext context) {
    // The loaded card owns its own RefreshIndicator (it IS the scrollable);
    // wrapping it again here would nest two indicators on one gesture.
    if (state is DiscoveryLoaded &&
        !(state as DiscoveryLoaded).isEmpty &&
        !(state as DiscoveryLoaded).isExhausted) {
      return _buildContent(context);
    }
    return RefreshIndicator(
      color: QeranColors.wine,
      onRefresh: () => context.read<DiscoveryCubit>().refresh(),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final s = state;
    if (s is DiscoveryInitial || s is DiscoveryLoading) {
      return const DiscoveryCardSkeleton();
    }
    if (s is DiscoveryFailure) {
      return _ScrollableCenter(
        child: QeranErrorState(
          title: LocaleKeys.discovery_load_failed.t(context),
          message: s.message.t(context),
          retryLabel: LocaleKeys.discovery_error_retry.t(context),
          onRetry: () => context.read<DiscoveryCubit>().loadInitial(),
        ),
      );
    }
    if (s is DiscoveryLoaded) {
      if (s.isEmpty || s.isExhausted) {
        // Deck ran dry. If more pages exist, the user out-swiped the loaded
        // deck while the next page is still loading — show a loader and make
        // sure a prefetch is in flight (once exhausted `current` is null, so
        // like()/pass() no-op and the cubit can't self-recover). Scheduled
        // post-frame so the prefetch's emit never lands during this build.
        // Only the genuine end-of-list (`!hasMore`) shows the terminal empty
        // view.
        if (s.hasMore) {
          final cubit = context.read<DiscoveryCubit>();
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => cubit.ensurePrefetch(),
          );
          return const DiscoveryCardSkeleton();
        }
        return const _ScrollableCenter(child: DiscoveryEmptyView());
      }
      return _ProfilePage(loaded: s, scrollOffset: scrollOffset);
    }
    if (s is DiscoveryDailyLimit) {
      return DiscoveryDailyLimitView(resetAt: s.resetAt);
    }
    return const SizedBox.shrink();
  }
}

/// The loaded discovery feed: one full-bleed [DiscoveryUnifiedCard] filling
/// the viewport. No peek layer — a full-screen surface has nothing to peek
/// out from behind it; the swipe replaces the surface wholesale.
class _ProfilePage extends StatefulWidget {
  final DiscoveryLoaded loaded;
  final ValueNotifier<double> scrollOffset;
  const _ProfilePage({required this.loaded, required this.scrollOffset});

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  String? _precachedNextProfileId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleNextPhotoPrecache();
    _hydrateCurrent();
  }

  @override
  void didUpdateWidget(covariant _ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loaded.next?.id != widget.loaded.next?.id) {
      _scheduleNextPhotoPrecache();
    }
    if (oldWidget.loaded.current?.id != widget.loaded.current?.id) {
      _hydrateCurrent();
    }
  }

  /// Fetches the current card's full profile so the below-the-fold sections
  /// are already in place by the time the user scrolls to them — no spinner
  /// on a scroll, and no fetch storm while swiping quickly. Cached by id, so
  /// undo never refetches.
  void _hydrateCurrent() {
    final current = widget.loaded.current;
    if (current == null) return;
    context.read<DiscoveryHydrationCubit>().hydrate(current.id);
  }

  void _scheduleNextPhotoPrecache() {
    final next = widget.loaded.next;
    if (next == null || next.id == _precachedNextProfileId) return;
    final imageUrl = _primaryImageUrl(next);
    if (imageUrl.isEmpty) return;
    _precachedNextProfileId = next.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(precacheDiscoveryPhoto(context, imageUrl));
    });
  }

  String _primaryImageUrl(DiscoveryProfile profile) {
    if (profile.images.isEmpty) return '';
    return profile.images
        .firstWhere(
          (image) => image.isProfile,
          orElse: () => profile.images.first,
        )
        .url;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final navClearance =
            QeranBottomNav.contentClearance(context) +
            (isLandscape ? 12.0 : 24.0);
        final profile = widget.loaded.current!;
        // constraints.maxHeight is already the area below the status bar (the
        // screen-level SafeArea), so this is the visible viewport — the same
        // height the first screenful is padded out to.
        final viewportHeight = constraints.maxHeight;
        // Landscape has far less height to spend, so the photo takes a
        // smaller share and the profile starts sooner.
        final photoHeight = viewportHeight *
            (isLandscape
                ? kDiscoveryPhotoFractionLandscape
                : kDiscoveryPhotoFraction);

        // Zero left/right margins: the surface is the screen. The bottom
        // clearance lives INSIDE the scroll so content can travel past the
        // action cluster instead of being boxed above it.
        return DiscoveryUnifiedCard(
          profile: profile,
          viewportHeight: viewportHeight,
          photoHeight: photoHeight,
          bottomInset: navClearance + _kActionZoneClearance,
          scrollOffset: widget.scrollOffset,
          onFilterTap: () => _openFilters(context),
        );
      },
    );
  }
}

/// Floating action bar — anchored to the bottom of the viewport,
/// transparent backdrop, sits over the scrolling profile body. Keeps
/// like / pass / undo reachable from any scroll position. The pill
/// buttons own their own visuals so there's no surrounding white
/// container.
///
/// Stateful so the Like API, heart burst and card eject can overlap safely.
/// Pass, Undo, and horizontal swipe gestures stay immediate. A re-entry flag
/// prevents double-tap stacking during the short sequence.
class _FloatingActionBar extends StatefulWidget {
  final DiscoveryState state;
  final void Function(Offset origin) onLikeBurst;
  final ValueNotifier<double> scrollOffset;

  const _FloatingActionBar({
    required this.state,
    required this.onLikeBurst,
    required this.scrollOffset,
  });

  @override
  State<_FloatingActionBar> createState() => _FloatingActionBarState();
}

class _FloatingActionBarState extends State<_FloatingActionBar> {
  /// Matches `DiscoveryLikeBurst` total duration.
  static const Duration _likeBurstWait = Duration(milliseconds: 480);

  /// Let the heart clearly leave the button before the card starts moving.
  /// The API already runs in parallel from t=0.
  static const Duration _minimumEjectLead = Duration(milliseconds: 300);

  bool _likePending = false;

  @override
  void dispose() {
    super.dispose();
  }

  /// Tap-driven Like flow with the API firing at tap time (parallel
  /// with the heart burst), the eject conditional on the outcome, and
  /// the cubit's emit deferred until the heart finishes:
  ///
  /// ```
  /// tap ──┬── spawn heart (480 ms)
  ///       └── cubit.like(outcomeNotifier, advanceGate)
  ///                ├── fires API
  ///                ├── notifies outcomeNotifier when server responds
  ///                └── awaits advanceGate before emitting state
  /// ```
  ///
  /// Once the minimum lead and API outcome are ready, an accepted card ejects
  /// while the heart finishes. Paywall / network failures skip the eject so
  /// the card stays visible. The cubit gate releases only after both visuals
  /// settle.
  void _scheduleLike(DiscoveryDeckAnimationController controller) {
    if (_likePending) return;
    if (controller.isAnimating) return;
    _likePending = true;
    unawaited(_runLikeFlow(controller));
  }

  Future<void> _runLikeFlow(DiscoveryDeckAnimationController controller) async {
    final cubit = context.read<DiscoveryCubit>();
    final outcomeNotifier = Completer<Either<Failure, LikeOutcome>>();
    final advanceGate = Completer<void>();
    // Fire API at tap time. The cubit will await the gate before
    // emitting; it also fires outcomeNotifier the moment the server
    // responds (well before the gate, typically).
    unawaited(
      cubit.like(
        outcomeNotifier: outcomeNotifier,
        advanceGate: advanceGate.future,
      ),
    );
    final heartTimer = Future<void>.delayed(_likeBurstWait);
    try {
      await Future<void>.delayed(_minimumEjectLead);
      if (!mounted) return;
      // No timeout here: the use case already maps transport timeouts to a
      // Failure, and advancing before the server result could remove a card
      // that actually needs to stay (paywall/network).
      final result = await outcomeNotifier.future;
      if (!mounted) return;
      final shouldEject = result.fold<bool>(
        (_) => false, // network/unknown — keep the card
        (outcome) => switch (outcome) {
          // Accepted, or "stale" failures where the server already
          // disqualified the card — advance with an eject visual.
          LikeAccepted() => true,
          LikeAlreadyPending() => true,
          LikeGenderMismatch() => true,
          LikeUserUnavailable() => true,
          // Subscription / quota exhausted — paywall slides up, card
          // stays in place.
          LikePaywall() => false,
          // Own profile under review — like is gated; keep the card in place.
          LikeUnderReview() => false,
        },
      );
      if (shouldEject && !controller.isAnimating) {
        // Runs the eject animation. `_runLikeSequence` calls
        // `cubit.like()` at the end — that call no-ops via the cubit's
        // in-flight guard (the original `like()` is still awaiting the
        // gate below), so no duplicate API request fires.
        await controller.triggerLike();
      }
      await heartTimer;
    } finally {
      _likePending = false;
      // Always release the gate so the cubit's in-flight `like()` can
      // drain its try/finally — leaving the gate open would freeze
      // future Like attempts behind the cubit's `_mutationInFlight`.
      if (!advanceGate.isCompleted) advanceGate.complete();
    }
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
      // At the top the buttons float over the empty paper under نبذة عني, so
      // a backdrop would be pure decoration; it fades in only once profile
      // content is actually passing behind them.
      child: ValueListenableBuilder<double>(
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
                  unawaited(animController.triggerUndo(onUndoCall: cubit.undo));
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
    );
  }
}

/// Wraps a child in an always-scrollable view so `RefreshIndicator`
/// works even when there is no real content to scroll (loading /
/// empty / error states).
class _ScrollableCenter extends StatelessWidget {
  final Widget child;
  const _ScrollableCenter({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}

/// Opens the dynamic filter sheet and forwards the user's selections
/// into [DiscoveryCubit.applyFilters].
///
/// The sheet is seeded with the deck's currently-applied selections so
/// previously-picked facets show as selected. On Save:
/// * Dismissed (null result) → no-op (keeps the applied filters).
/// * Empty payload → applies `null` (clears active filters).
/// * Non-empty payload → applies it; the cubit reloads from page 1 and
///   future prefetches carry the same params.
///
/// Either way the structured selections are written back so the next open
/// reflects the applied state.
Future<void> _openFilters(BuildContext context) async {
  final cubit = context.read<DiscoveryCubit>();
  final result = await showDiscoveryFilterSheet(
    context,
    initialSelections: cubit.activeFilterSelections,
  );
  if (result == null) return;
  if (!context.mounted) return;
  final payload = result.payload;
  await cubit.applyFilters(
    payload.isEmpty ? null : payload,
    selections: result.selections,
  );
}
