import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';

import '../../domain/entities/discovery_profile.dart';
import '../blocs/discovery_cubit.dart';
import 'discovery_card.dart';
import 'discovery_deck_animator.dart';
import 'discovery_merged_profile_body.dart';
import 'discovery_swipe_handler.dart';

/// The merged discovery surface for ONE profile: a single full-bleed scroll
/// whose first screenful is the photo and whose continuation is the whole
/// profile, inline.
///
/// This replaces the old floating rounded card with a fixed 54/46 photo/data
/// split and the tap-through to a separate Full Profile screen. The photo now
/// runs edge to edge from under the status bar down to the bottom nav, and
/// scrolling DOWN reveals نبذة عن شريك الحياة, the Q&A groups and الاهتمامات
/// in place. The action buttons act; nothing navigates.
///
/// The deck-animator → swipe-handler nesting is unchanged, so horizontal
/// like / pass / undo / eject behave exactly as before — except the swipe is
/// now gated on being scrolled to the top (see [_atTop]).
class DiscoveryUnifiedCard extends StatefulWidget {
  const DiscoveryUnifiedCard({
    super.key,
    required this.profile,
    required this.photoHeight,
    required this.bottomInset,
    this.onFilterTap,
  });

  final DiscoveryProfile profile;

  /// Height of the first screenful of photo. The merged layout has no bounded
  /// parent height inside the scroll, so this is computed by the caller from
  /// the viewport.
  final double photoHeight;

  /// Trailing clearance so the last section can scroll above the floating
  /// action cluster and the bottom nav.
  final double bottomInset;

  final VoidCallback? onFilterTap;

  @override
  State<DiscoveryUnifiedCard> createState() => _DiscoveryUnifiedCardState();
}

class _DiscoveryUnifiedCardState extends State<DiscoveryUnifiedCard> {
  /// Drives the swipe gate. A ValueNotifier rather than setState so a scroll
  /// never rebuilds the photo — it would re-run the sigma blur every frame.
  final ValueNotifier<bool> _atTop = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _atTop.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    _atTop.value = notification.metrics.pixels <= 0.5;
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
                      // The photo is expensive to raster (sigma blur), and it
                      // now scrolls. Boundaried so scrolling translates a
                      // cached layer instead of re-blurring each frame.
                      child: RepaintBoundary(
                        child: DiscoveryImagePanel(
                          profile: widget.profile,
                          height: widget.photoHeight,
                          onFilterTap: widget.onFilterTap,
                        ),
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
