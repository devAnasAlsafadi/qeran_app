import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';

import '../../domain/entities/discovery_profile.dart';
import '../blocs/discovery_cubit.dart';
import 'discovery_deck_animator.dart';
import 'discovery_first_screenful.dart';
import 'discovery_merged_profile_body.dart';
import 'discovery_swipe_handler.dart';

/// Scroll distance over which the compatibility pill fades onto the photo.
///
/// It is deliberately absent at rest: the first thing the card shows is the
/// person, and a percentage next to their name reads as a verdict before the
/// user has read anything. Scrolling into the profile is the moment it becomes
/// useful, so that is when it arrives.
const double _kMatchPillRevealDistance = 90.0;

/// The merged discovery surface for ONE profile: a single full-bleed scroll
/// whose first screenful is the photo plus نبذة عني, followed by a small teaser
/// of the next section so the continuation is discoverable without hiding any
/// of the intro.
///
/// At rest the intro area ([DiscoveryFirstScreenful]) reserves one viewport
/// minus a small peek, so نبذة عن شريك الحياة starts inside the bottom edge as
/// an intentional scroll cue. The remaining surplus then collapses as the user
/// scrolls, so the sections arrive flush under the chips instead of behind a
/// screen-tall blank.
///
/// The deck-animator → swipe-handler nesting is unchanged, so horizontal
/// like / pass / undo / eject behave exactly as before — except the swipe is
/// gated on being scrolled to the top.
class DiscoveryUnifiedCard extends StatefulWidget {
  const DiscoveryUnifiedCard({
    super.key,
    required this.profile,
    required this.viewportHeight,
    required this.photoHeight,
    required this.bottomInset,
    required this.scrollOffset,
    this.onFilterTap,
  });

  final DiscoveryProfile profile;

  /// Height of the visible area (already excluding the status bar). The first
  /// screenful reserves slightly less than this at rest so the next section
  /// peeks above the fold.
  final double viewportHeight;

  /// Height of the photo block.
  final double photoHeight;

  /// Trailing clearance so the last section can scroll above the floating
  /// action cluster and the bottom nav.
  final double bottomInset;

  /// Published scroll offset — drives the swipe gate here and the action
  /// cluster's backdrop in the screen layer above.
  final ValueNotifier<double> scrollOffset;

  final VoidCallback? onFilterTap;

  @override
  State<DiscoveryUnifiedCard> createState() => _DiscoveryUnifiedCardState();
}

class _DiscoveryUnifiedCardState extends State<DiscoveryUnifiedCard> {
  /// Drives the swipe gate. Derived from [DiscoveryUnifiedCard.scrollOffset]
  /// rather than setState so a scroll never rebuilds the photo — that would
  /// re-run the sigma blur every frame.
  late final ValueNotifier<bool> _atTop = ValueNotifier<bool>(true);

  /// 0 → the compatibility pill is hidden (first open), 1 → fully faded in.
  /// Derived here rather than inside the photo so a scroll repaints the pill
  /// alone.
  late final ValueNotifier<double> _pillReveal = ValueNotifier<double>(0);

  @override
  void dispose() {
    _atTop.dispose();
    _pillReveal.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    final pixels = notification.metrics.pixels;
    final offset = pixels < 0 ? 0.0 : pixels;
    widget.scrollOffset.value = offset;
    _atTop.value = pixels <= 0.5;
    _pillReveal.value = (offset / _kMatchPillRevealDistance).clamp(0.0, 1.0);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      // Keying on the profile id rebuilds the whole subtree — including the
      // Scrollable — when the deck advances, so the next card always opens at
      // the top instead of inheriting the previous card's read position.
      key: ValueKey<String>(widget.profile.id),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        builder: (context, progress, child) => Transform.translate(
          offset: Offset(0, 8 * (1 - progress)),
          child: child,
        ),
        child: DiscoveryDeckAnimator(
          child: DiscoverySwipeHandler(
            enabled: _atTop,
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: RefreshIndicator(
                color: QeranColors.wine,
                onRefresh: () => context.read<DiscoveryCubit>().refresh(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: DiscoveryFirstScreenful(
                        profile: widget.profile,
                        viewportHeight: widget.viewportHeight,
                        photoHeight: widget.photoHeight,
                        scrollOffset: widget.scrollOffset,
                        pillReveal: _pillReveal,
                        onFilterTap: widget.onFilterTap,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: DiscoveryMergedProfileBody(
                        profile: widget.profile,
                        bottomInset: widget.bottomInset,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
