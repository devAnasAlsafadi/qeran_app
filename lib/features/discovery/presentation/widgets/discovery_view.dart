import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_error_state.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
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
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_state.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/discovery_profile.dart';
import '../../domain/entities/like_outcome.dart';
import '../blocs/discovery_cubit.dart';
import '../blocs/discovery_state.dart';
import '../screens/discovery_filter_sheet.dart';
import 'discovery_action_bar.dart';
import 'discovery_card.dart';
import 'discovery_deck_animation_controller.dart';
import 'discovery_deck_animator.dart';
import 'discovery_daily_limit_view.dart';
import 'discovery_empty_view.dart';
import 'discovery_like_burst.dart';
import 'discovery_swipe_handler.dart';
import 'discovery_top_bar.dart';

/// Reusable Discovery content. Self-contained — provides its own
/// `DiscoveryCubit` and drives `loadInitial` on first build.
///
/// New layout: the entire profile is one vertical scroll. The image
/// card sits at the top and scrolls upward as the user reads down
/// through the continuous profile body. The action bar floats over
/// the bottom of the viewport (no surrounding card) and stays
/// accessible from every scroll position. Horizontal drags on the
/// image trigger the existing swipe / like / pass / undo flow; the
/// outer vertical scroll competes in the gesture arena so the two
/// axes never fight.
class DiscoveryView extends StatelessWidget {
  /// When true, renders [DiscoveryTopBar] pinned above the scroll.
  /// Embedders that already supply their own header pass `false`.
  final bool showTopBar;

  const DiscoveryView({super.key, this.showTopBar = true});

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
      child: _DiscoveryContent(showTopBar: showTopBar),
    );
  }
}

class _DiscoveryContent extends StatefulWidget {
  final bool showTopBar;
  const _DiscoveryContent({required this.showTopBar});

  @override
  State<_DiscoveryContent> createState() => _DiscoveryContentState();
}

// ── Design constants ────────────────────────────────────────────────────────
const double _kStackHPad = 18.0;
const double _kStackTPad = 16.0;
const double _kPeekHeight = 20.0;
const double _kBodyHPad = QeranSpacing.s20;
const double _kNavActionGap = 28.0;
const double _kActionBarReserve = 120.0;
const double _kImageHeightFraction = 0.51;

/// Extra top padding inserted before the image card when the home shell's
/// floating filter/notifications buttons sit over the scroll (showTopBar
/// is false). Pushes the card start below those buttons (top SafeArea +
/// 8 dp pad + 44 dp button) so they no longer overlap the image.
const double _kOverlayClearance = 52.0;

/// Negative offset applied to the white profile-body card so it slides
/// up under the image card's rounded bottom — matches the Figma "sheet
/// overlapping the image" look from the previous layout.
const double _kBodyOverlap = 20.0;

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
                message:
                    LocaleKeys.discovery_like_user_unavailable.t(context),
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
              // Issue 1 fix — fixed white backdrop covering the lower
              // portion of the screen. Sits BEHIND the scroll content so
              // it only shows through where the scroll content doesn't
              // paint (e.g. the 20 dp gap the body card's overlap
              // Transform creates at max scroll, and the margins around
              // the bottom-nav pill). The scroll's image + body cards
              // are opaque, so this backdrop is invisible everywhere
              // they paint — no visual side effects above.
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 260,
                child: ColoredBox(color: QeranColors.paper),
              ),
              Positioned.fill(child: _buildBody(context, state)),
              if (!widget.showTopBar)
                Positioned(
                  top: 0,
                  left: QeranSpacing.s16,
                  right: QeranSpacing.s16,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.only(top: QeranSpacing.s8),
                      child: _OverlayControls(
                        onFilterTap: () => _openFilters(context),
                        onNotificationsTap: () => openNotifications(context),
                      ),
                    ),
                  ),
                ),
              if (!_isFullScreenReplacement(state))
                _FloatingActionBar(
                  state: state,
                  onLikeBurst: _spawnLikeBurst,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, DiscoveryState state) {
    if (widget.showTopBar) {
      return Column(
        children: [
          DiscoveryTopBar(
            onFilterTap: () => _openFilters(context),
            onNotificationsTap: () => openNotifications(context),
          ),
          const SizedBox(height: QeranSpacing.s12),
          Expanded(
            child: _ScrollableProfile(
              state: state,
              hasOverlayControls: false,
            ),
          ),
        ],
      );
    }
    return _ScrollableProfile(state: state, hasOverlayControls: true);
  }
}

/// The single vertical scroll that owns the entire Discovery profile —
/// image card at the top, full continuous body underneath. Loading /
/// failure / empty states reuse the existing always-scrollable
/// containers so `RefreshIndicator` keeps working.
///
/// [hasOverlayControls] is true when the floating filter / notifications
/// buttons sit over the scroll (home shell). The image card then needs
/// extra top padding to clear them.
class _ScrollableProfile extends StatelessWidget {
  final DiscoveryState state;
  final bool hasOverlayControls;
  const _ScrollableProfile({
    required this.state,
    required this.hasOverlayControls,
  });

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
      return const _ScrollableCenter(child: QeranLoader());
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
          return const _ScrollableCenter(child: QeranLoader());
        }
        return const _ScrollableCenter(child: DiscoveryEmptyView());
      }
      return _ProfilePage(
        loaded: s,
        hasOverlayControls: hasOverlayControls,
      );
    }
    if (s is DiscoveryDailyLimit) {
      return DiscoveryDailyLimitView(resetAt: s.resetAt);
    }
    return const SizedBox.shrink();
  }
}

/// One vertical scroll containing the image card (with peek deck
/// behind) and the continuous profile body. Image height is fixed at
/// 51 % of the viewport so the deck visuals match the previous Figma
/// layout; the body below has unbounded height and drives the scroll.
///
/// Stateful so we can own a [ScrollController] and glide the offset
/// back to the top when the active profile changes (like / pass /
/// undo / swipe). Without that reset, a deep-scrolled body carries
/// its offset over to the next profile and the new content reads as a
/// frozen jump — the body cross-fade does its job, but the eye sees
/// mid-content morphing into different mid-content. The glide runs
/// alongside the body's fade-and-slide so the perceived transition is
/// one graceful motion rather than two separate beats.
class _ProfilePage extends StatefulWidget {
  final DiscoveryLoaded loaded;
  final bool hasOverlayControls;
  const _ProfilePage({
    required this.loaded,
    required this.hasOverlayControls,
  });

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  final ScrollController _scrollController = ScrollController();
  String? _lastProfileId;
  bool _bannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _lastProfileId = widget.loaded.current?.id;
  }

  @override
  void didUpdateWidget(_ProfilePage old) {
    super.didUpdateWidget(old);
    final newId = widget.loaded.current?.id;
    if (newId == null || newId == _lastProfileId) return;
    final wasInitialized = _lastProfileId != null;
    _lastProfileId = newId;
    if (!wasInitialized) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scrollController.hasClients) return;
      if (_scrollController.offset <= 0.5) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageHeight = constraints.maxHeight * _kImageHeightFraction;
        final bottomInset = MediaQuery.of(context).padding.bottom;
        final profile = widget.loaded.current!;
        final nextProfile = widget.loaded.next;
        final topClearance =
            widget.hasOverlayControls ? _kOverlayClearance : 0.0;

        final subState = context.watch<CurrentSubscriptionCubit>().state;
        final hasActiveSub = subState is CurrentSubscriptionLoaded &&
            subState.subscription.isCurrentlyActive;
        final showBanner = !hasActiveSub && !_bannerDismissed;

        final bannerTopClearance = showBanner && widget.hasOverlayControls ? topClearance : 0.0;
        final cardTopClearance = !showBanner && widget.hasOverlayControls ? topClearance : 0.0;

        return SingleChildScrollView(
          controller: _scrollController,
          // BouncingScrollPhysics gives a smoother deceleration curve
          // than ClampingScrollPhysics and a more "premium" feel on
          // both iOS and Android. Wrapped in AlwaysScrollableScrollPhysics
          // so RefreshIndicator keeps working when content is short.
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showBanner)
                _UpgradeFeedBanner(
                  topClearance: bannerTopClearance,
                  onDismiss: () => setState(() => _bannerDismissed = true),
                ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    _kStackHPad,
                    _kStackTPad + cardTopClearance,
                    _kStackHPad,
                    0,
                  ),
                  // RepaintBoundary isolates the heavy ImageFilter.blur
                  // inside `DiscoveryBlurredImage` so a vertical scroll
                  // just translates the cached raster instead of
                  // re-running the blur every frame. Cheap to add,
                  // noticeably smoother scroll over the image area.
                  child: RepaintBoundary(
                    child: SizedBox(
                      height: imageHeight,
                      child: Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.none,
                        children: [
                          if (nextProfile != null)
                            _PeekCardLayer(profile: nextProfile),
                          Padding(
                            padding:
                                const EdgeInsets.only(top: _kPeekHeight),
                            child: _ImageCard(profile: profile),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Negative offset slides the white profile-body card
              // upward into the image card's rounded bottom — the
              // "sheet overlapping the image" look. Transform.translate
              // only shifts visually; the column's layout is unchanged
              // so the bottom action-bar reservation stays correct.
              Transform.translate(
                offset: const Offset(0, -_kBodyOverlap),
                child: Container(
                  decoration: BoxDecoration(
                    color: QeranColors.paper,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(QeranRadii.panel),
                    ),
                    // Soft upward shadow at the sheet's top edge to
                    // separate the body card from the image. The
                    // QeranShadows tokens (e1/e2/e3) are all downward
                    // shadows; this specialised upward variant uses
                    // the same wine-tinted palette via `wine08`.
                    boxShadow: const [
                      BoxShadow(
                        color: QeranColors.wine08,
                        blurRadius: 24,
                        offset: Offset(0, -6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    _kBodyHPad,
                    QeranSpacing.s32,
                    _kBodyHPad,
                    QeranSpacing.s16,
                  ),
                  // Directional fade + slide: old body slides UP and
                  // fades out, new body slides UP from below and fades
                  // in. Both halves of the transition are visible at
                  // ~6 % of the body height (~30–40 px) — noticeable
                  // without feeling theatrical. 420 ms is the upper
                  // bound for "single calm beat"; longer would start
                  // to feel like a wait. No extra opacity layer over
                  // the blurred image — this switcher only wraps the
                  // text body, so it can't trigger the Impeller atlas
                  // race that ImageFilter.blur is sensitive to.
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) {
                      return _ProfileBodyTransition(
                        animation: animation,
                        child: child,
                      );
                    },
                    // Discovery card body is intentionally slim — only
                    // about-me preview (2 lines max) + insideCard chips.
                    // Long-form sections live on FullProfileDetailsScreen,
                    // reachable via the card tap (`_openDetails`).
                    child: RepaintBoundary(
                      key: ValueKey<String>(profile.id),
                      child: DiscoveryInfoPanel(profile: profile),
                    ),
                  ),
                ),
              ),
              SizedBox(height: bottomInset + _kActionBarReserve),
            ],
          ),
        );
      },
    );
  }
}

/// Directional slide+fade for the profile-body AnimatedSwitcher.
///
/// AnimatedSwitcher applies a single `transitionBuilder` to BOTH the
/// outgoing and incoming children, with the same `Tween`. That makes
/// it impossible to drive opposing motions (old slides up + out, new
/// slides up + in) from a single Tween. This helper inspects the
/// animation's starting value once at [initState] — `1.0` means the
/// AnimatedSwitcher just handed us an outgoing entry (was previously
/// the live child at full opacity), `0.0` means an incoming one — and
/// picks the matching Tween so both halves of the swap visibly move
/// upward.
///
/// Outgoing: position interpolates `(0, 0) → (0, -0.05)` as animation
/// runs `1 → 0`. Slides up + fades.
/// Incoming: position interpolates `(0, 0.05) → (0, 0)` as animation
/// runs `0 → 1`. Slides up from below + fades in.
class _ProfileBodyTransition extends StatefulWidget {
  final Animation<double> animation;
  final Widget child;

  const _ProfileBodyTransition({
    required this.animation,
    required this.child,
  });

  @override
  State<_ProfileBodyTransition> createState() =>
      _ProfileBodyTransitionState();
}

class _ProfileBodyTransitionState extends State<_ProfileBodyTransition> {
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final isOutgoing = widget.animation.value >= 0.5;
    _slide = Tween<Offset>(
      begin: isOutgoing
          ? const Offset(0, -0.05)
          : const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(widget.animation);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.animation,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// The image card itself — wraps the deck animator and the swipe
/// handler so horizontal drags on the image area drive the same
/// like / pass / undo / eject flow as before. Extracted so the parent
/// `_ProfilePage` stays readable.
class _ImageCard extends StatelessWidget {
  final DiscoveryProfile profile;
  const _ImageCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: QeranRadii.panelR,
        boxShadow: QeranShadows.e3,
      ),
      child: ClipRRect(
        borderRadius: QeranRadii.panelR,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) {
            final scale =
                Tween<double>(begin: 0.94, end: 1.0).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: scale, child: child),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<String>(profile.id),
            child: DiscoveryDeckAnimator(
              child: DiscoverySwipeHandler(
                child: Builder(
                  builder: (ctx) => DiscoveryImagePanel(
                    profile: profile,
                    onTap: () => _openDetails(ctx, profile),
                    showOverlayActions: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating action bar — anchored to the bottom of the viewport,
/// transparent backdrop, sits over the scrolling profile body. Keeps
/// like / pass / undo reachable from any scroll position. The pill
/// buttons own their own visuals so there's no surrounding white
/// container.
///
/// Stateful so the Like tap can defer `triggerLike()` until the
/// 1050 ms flying-heart burst completes — otherwise the card swap
/// cuts the heart mid-arc. Pass, Undo, and horizontal swipe gestures
/// stay immediate. A re-entry flag prevents double-tap stacking
/// during the wait.
class _FloatingActionBar extends StatefulWidget {
  final DiscoveryState state;
  final void Function(Offset origin) onLikeBurst;

  const _FloatingActionBar({
    required this.state,
    required this.onLikeBurst,
  });

  @override
  State<_FloatingActionBar> createState() => _FloatingActionBarState();
}

class _FloatingActionBarState extends State<_FloatingActionBar> {
  /// Matches `DiscoveryLikeBurst` total duration. The heart finishes its
  /// travel + settle exactly here; the action bar uses this as the
  /// floor for the visible response (heart must complete before any
  /// paywall / advance / toast fires).
  static const Duration _likeBurstWait = Duration(milliseconds: 1050);

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
  /// tap ──┬── spawn heart (1050 ms)
  ///       └── cubit.like(outcomeNotifier, advanceGate)
  ///                ├── fires API
  ///                ├── notifies outcomeNotifier when server responds
  ///                └── awaits advanceGate before emitting state
  /// ```
  ///
  /// After the 1050 ms heart wait, we have the outcome in hand. Eject
  /// runs only when the outcome warrants advancing the deck (accepted
  /// + stale failures). Paywall / network failures skip the eject so
  /// the card stays visible behind the paywall sheet. The gate then
  /// releases and the cubit emits — the listener picks up paywall /
  /// toast and the AnimatedSwitcher handles the cross-fade for any
  /// advance.
  void _scheduleLike(DiscoveryDeckAnimationController controller) {
    if (_likePending) return;
    if (controller.isAnimating) return;
    _likePending = true;
    unawaited(_runLikeFlow(controller));
  }

  Future<void> _runLikeFlow(
    DiscoveryDeckAnimationController controller,
  ) async {
    final cubit = context.read<DiscoveryCubit>();
    final outcomeNotifier = Completer<Either<Failure, LikeOutcome>>();
    final advanceGate = Completer<void>();
    // Fire API at tap time. The cubit will await the gate before
    // emitting; it also fires outcomeNotifier the moment the server
    // responds (well before the gate, typically).
    unawaited(cubit.like(
      outcomeNotifier: outcomeNotifier,
      advanceGate: advanceGate.future,
    ));
    final heartTimer = Future<void>.delayed(_likeBurstWait);
    try {
      // Wait for BOTH the heart (1050 ms floor) AND the API outcome.
      // In practice the API usually resolves inside the heart window;
      // when it doesn't we wait a bit longer rather than emit early.
      await heartTimer;
      if (!mounted) return;
      _likePending = false;
      Either<Failure, LikeOutcome>? result;
      if (outcomeNotifier.isCompleted) {
        result = await outcomeNotifier.future;
      } else {
        // API still pending — keep the heart visible by holding the
        // gate while we wait. No timeout: the use case eventually
        // resolves to a Failure on transport timeout.
        result = await outcomeNotifier.future;
      }
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
        },
      );
      if (shouldEject && !controller.isAnimating) {
        // Runs the eject animation. `_runLikeSequence` calls
        // `cubit.like()` at the end — that call no-ops via the cubit's
        // in-flight guard (the original `like()` is still awaiting the
        // gate below), so no duplicate API request fires.
        await controller.triggerLike();
      }
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
    final hasActive =
        loaded != null && !loaded.isEmpty && !loaded.isExhausted;
    final hasUndoTarget = loaded != null && loaded.currentIndex > 0;
    final animController = DeckAnimationScope.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // Enable state derives from the cubit only (see the previous
    // _ActionBarArea note): gating on the animator's busy flag caused
    // a synchronized colour flash across all three buttons. The Like
    // re-entry guard lives inside `_scheduleLike` so the button stays
    // visually enabled during the 1050 ms wait — rapid taps simply
    // no-op without disabling the press feedback.
    return Positioned(
      left: _kBodyHPad,
      right: _kBodyHPad,
      bottom: bottomInset + _kNavActionGap,
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
Future<void> _openDetails(BuildContext context, DiscoveryProfile profile) async {
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
/// * Dismissed (null result) → no-op.
/// * Empty payload → applies `null` (clears active filters).
/// * Non-empty payload → applies it; the cubit reloads from page 1
///   and future prefetches carry the same params.
Future<void> _openFilters(BuildContext context) async {
  final cubit = context.read<DiscoveryCubit>();
  final result = await showDiscoveryFilterSheet(context);
  if (result == null) return;
  if (!context.mounted) return;
  await cubit.applyFilters(result.isEmpty ? null : result);
}

class _OverlayControls extends StatelessWidget {
  final VoidCallback onFilterTap;
  final VoidCallback onNotificationsTap;

  const _OverlayControls({
    required this.onFilterTap,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _OverlayCircleIcon(
          icon: Icons.tune_rounded,
          onPressed: onFilterTap,
        ),
        const Spacer(),
        BlocBuilder<NotificationBadgeCubit, bool>(
          builder: (context, hasUnread) => _OverlayCircleIcon(
            icon: Icons.notifications_none_rounded,
            onPressed: onNotificationsTap,
            badge: hasUnread ? const _BellUnreadDot() : null,
          ),
        ),
      ],
    );
  }
}

class _OverlayCircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  /// Small unread marker drawn at the top-trailing corner (directional).
  final Widget? badge;

  const _OverlayCircleIcon({
    required this.icon,
    required this.onPressed,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final button = DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: QeranShadows.e2,
      ),
      child: Material(
        color: QeranColors.paper,
        shape: const CircleBorder(
          side: BorderSide(color: QeranColors.wine08),
        ),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 22,
              color: QeranColors.wine,
            ),
          ),
        ),
      ),
    );
    if (badge == null) return button;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        PositionedDirectional(top: 1, end: 1, child: badge!),
      ],
    );
  }
}

/// Subtle on-brand unread dot for the discovery bell — wine with a paper ring
/// so it reads cleanly on the white bell.
class _BellUnreadDot extends StatelessWidget {
  const _BellUnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: QeranColors.wine,
        border: Border.all(color: QeranColors.paper, width: 1.5),
      ),
    );
  }
}

/// Background layer showing the next profile's image behind the active
/// card. At rest: scale 0.94 (topCenter aligned), opacity 0.60, offset
/// 8 dp down. As [DiscoveryDeckAnimationController.deckProgress] rises
/// toward 1.0 (drag / exit), the peek card promotes to full size, full
/// opacity, and zero vertical offset — creating the illusion of a real
/// layered deck.
///
/// [RepaintBoundary] isolates the image raster from the front-card
/// and surrounding scroll layers. [IgnorePointer] ensures no touches
/// escape.
class _PeekCardLayer extends StatelessWidget {
  final DiscoveryProfile profile;
  const _PeekCardLayer({required this.profile});

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
          child: ClipRRect(
            borderRadius: QeranRadii.panelR,
            child: DiscoveryImagePanel(
              profile: profile,
              onTap: null,
              showOverlayActions: false,
            ),
          ),
        ),
      ),
    );
  }
}

class _UpgradeFeedBanner extends StatelessWidget {
  final double topClearance;
  final VoidCallback onDismiss;

  const _UpgradeFeedBanner({
    required this.topClearance,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        _kStackHPad,
        topClearance + _kStackTPad,
        _kStackHPad,
        0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: QeranColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(QeranRadii.card),
        border: Border.all(color: QeranColors.gold.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: QeranColors.gold.withValues(alpha: 0.18),
              border: Border.all(color: QeranColors.gold, width: 1),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: QeranColors.goldDeep,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              LocaleKeys.discovery_upgrade_banner_message.t(context),
              style: QeranTypography.body.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                color: QeranColors.wine,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => NavigationManager.navigateTo(context, RouteNames.packagesScreen),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: QeranColors.wine,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                LocaleKeys.discovery_upgrade_banner_cta.t(context),
                style: QeranTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                  color: QeranColors.gold,
                ),
              ),
            ),
          ),
          QeranSpacing.hs8,
          GestureDetector(
            onTap: onDismiss,
            child: Icon(
              Icons.close_rounded,
              size: 18,
              color: QeranColors.wine.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

