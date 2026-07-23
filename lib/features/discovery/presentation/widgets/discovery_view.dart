import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_nav.dart';
import 'package:qeran/core/design_system/widgets/qeran_error_state.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/notifications/presentation/blocs/notification_badge_cubit.dart';
import 'package:qeran/features/notifications/presentation/routing/open_notifications.dart';
import 'package:qeran/features/profile/domain/entities/profile_entry_source.dart';
import 'package:qeran/features/profile/presentation/full_profile_details_args.dart';
import 'package:qeran/features/profile/presentation/other_profile_seed.dart';
import 'package:qeran/features/subscriptions/presentation/paywall/paywall_bottom_sheet.dart';
import 'package:qeran/features/subscriptions/presentation/paywall/paywall_intent.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/discovery_profile.dart';
import '../../domain/entities/like_outcome.dart';
import '../blocs/discovery_cubit.dart';
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
import 'discovery_top_bar.dart';
import 'discovery_unified_card.dart';

/// Reusable Discovery content. Self-contained — provides its own
/// `DiscoveryCubit` and drives `loadInitial` on first build.
///
/// Layout: a fixed page (no page scroll) — an optional upsell banner atop a
/// single [DiscoveryUnifiedCard] whose photo is fixed and whose data region
/// scrolls internally. The like / pass / undo cluster is pinned in a frosted
/// zone at the card's bottom. Horizontal drags run the existing swipe / like
/// / pass / undo flow; the card's inner vertical scroll competes in the
/// gesture arena so the two axes never fight.
class DiscoveryView extends StatelessWidget {
  const DiscoveryView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DiscoveryCubit>(
          create: (_) => sl<DiscoveryCubit>()..loadInitial(),
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
const double _kStackHPad = 18.0;
const double _kStackTPad = 4.0;
const double _kPeekHeight = 20.0;

/// Height reserved at the bottom of the card's internal scroll so the last
/// data chips can scroll clear of the pinned frosted action cluster.
const double _kActionZoneClearance = 128.0;

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
                _FloatingActionBar(state: state, onLikeBurst: _spawnLikeBurst),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, DiscoveryState state) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              QeranSpacing.s16,
              QeranSpacing.s8,
              QeranSpacing.s16,
              0,
            ),
            child: DiscoveryTopBar(
              onFilterTap: () => _openFilters(context),
              onNotificationsTap: () => openNotifications(context),
            ),
          ),
          const SizedBox(height: QeranSpacing.s4),
          Expanded(child: _ScrollableProfile(state: state)),
        ],
      ),
    );
  }
}

/// Owns the pull-to-refresh + the state switch below the top bar. Loading /
/// failure / empty states use always-scrollable containers so
/// `RefreshIndicator` keeps working; the loaded state renders [_ProfilePage]
/// (a fixed card whose data region scrolls internally).
class _ScrollableProfile extends StatelessWidget {
  final DiscoveryState state;
  const _ScrollableProfile({required this.state});

  @override
  Widget build(BuildContext context) {
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
      return _ProfilePage(loaded: s);
    }
    if (s is DiscoveryDailyLimit) {
      return DiscoveryDailyLimitView(resetAt: s.resetAt);
    }
    return const SizedBox.shrink();
  }
}

/// The loaded discovery feed: a single fixed [DiscoveryUnifiedCard] (photo +
/// internally-scrolling data), with the peek deck behind it. The page itself does
/// not scroll — only the card's inner data region does.
class _ProfilePage extends StatefulWidget {
  final DiscoveryLoaded loaded;
  const _ProfilePage({required this.loaded});

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  String? _precachedNextProfileId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleNextPhotoPrecache();
  }

  @override
  void didUpdateWidget(covariant _ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loaded.next?.id != widget.loaded.next?.id) {
      _scheduleNextPhotoPrecache();
    }
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
        // The card fills down to above the floating bottom-nav island with extra clearance
        // so the action buttons and floating nav never collide.
        final navClearance = QeranBottomNav.contentClearance(context) + 48.0;
        final profile = widget.loaded.current!;
        final nextProfile = widget.loaded.next;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  _kStackHPad,
                  _kStackTPad,
                  _kStackHPad,
                  0,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    if (nextProfile != null) const _PeekCardLayer(),
                    Padding(
                      padding: const EdgeInsets.only(top: _kPeekHeight),
                      child: DiscoveryUnifiedCard(
                        profile: profile,
                        onTapDetails: () => _openDetails(context, profile),
                        bottomContentInset: _kActionZoneClearance,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: navClearance),
          ],
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

  const _FloatingActionBar({required this.state, required this.onLikeBurst});

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
    final navClearance = QeranBottomNav.contentClearance(context) + 48.0;

    // Enable state derives from the cubit only (see the previous
    // _ActionBarArea note): gating on the animator's busy flag caused
    // a synchronized colour flash across all three buttons. The Like
    // re-entry guard lives inside `_scheduleLike` so the button stays
    // visually enabled during the short wait — rapid taps simply
    // no-op without disabling the press feedback.
    return Positioned(
      left: _kStackHPad + 14.0,
      right: _kStackHPad + 14.0,
      bottom: navClearance + 14.0,
      child: DiscoveryFrostedActionZone(
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

/// Pushes the reusable Full Profile Details screen with a Discovery
/// seed so the layout paints instantly while the by-id endpoint
/// hydrates in the background.
Future<void> _openDetails(
  BuildContext context,
  DiscoveryProfile profile,
) async {
  final result = await NavigationManager.navigateTo(
    context,
    RouteNames.fullProfileDetails,
    arguments: FullProfileDetailsArgs(
      userId: profile.id,
      initialData: OtherProfileSeed.fromDiscovery(profile),
      entry: ProfileEntrySource.discovery,
    ),
  );
  // SafetyMenuButton pops the details route returning the blocked userId. The
  // backend has already severed the user server-side, so a plain refresh drops
  // them from the deck (no fragile in-memory deck mutation).
  if (result is String && context.mounted) {
    context.read<DiscoveryCubit>().refresh();
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

/// Lightweight next-card silhouette. It preserves the layered-deck cue without
/// rendering a second live network image + sigma-24 blur during every drag
/// frame. The real next profile enters immediately after the short eject.
class _PeekCardLayer extends StatelessWidget {
  const _PeekCardLayer();

  static const double _peekScale = 0.94;
  static const double _peekOpacity = 0.60;
  static const double _peekOffsetDp = 8.0;

  @override
  Widget build(BuildContext context) {
    final deckProgress = DeckAnimationScope.of(context).deckProgress;
    return RepaintBoundary(
      child: IgnorePointer(
        child: ValueListenableBuilder<double>(
          valueListenable: deckProgress,
          builder: (context, rawProgress, child) {
            final t = Curves.easeOut.transform(rawProgress);
            final scale = _peekScale + (1.0 - _peekScale) * t;
            final dy = _peekOffsetDp * (1.0 - t);
            final opacity = _peekOpacity + (1.0 - _peekOpacity) * t;
            return Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0.0, dy),
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topCenter,
                  child: child,
                ),
              ),
            );
          },
          child: DecoratedBox(
            key: const ValueKey<String>('discovery-peek-silhouette'),
            decoration: BoxDecoration(
              borderRadius: QeranRadii.panelR,
              color: QeranColors.paper,
              border: Border.all(
                color: QeranColors.wine.withValues(alpha: 0.10),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: QeranColors.wine.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: QeranRadii.panelR,
              child: Column(
                children: [
                  Expanded(
                    flex: 51,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [QeranColors.wineLight, QeranColors.wine],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.layers_rounded,
                          color: QeranColors.gold40,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 49,
                    child: const ColoredBox(
                      color: QeranColors.paper,
                      child: Padding(
                        padding: EdgeInsets.all(QeranSpacing.s20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PeekSkeletonBar(width: 104, height: 12),
                            SizedBox(height: QeranSpacing.s12),
                            _PeekSkeletonBar(width: 220, height: 8),
                            SizedBox(height: QeranSpacing.s8),
                            _PeekSkeletonBar(width: 164, height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PeekSkeletonBar extends StatelessWidget {
  const _PeekSkeletonBar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: QeranColors.wine08,
          borderRadius: QeranRadii.pill,
        ),
      ),
    );
  }
}
