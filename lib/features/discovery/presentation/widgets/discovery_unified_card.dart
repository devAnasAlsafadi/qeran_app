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
/// whose first screenful is the photo plus نبذة عني, and whose continuation is
/// the rest of the profile, inline.
///
/// The first screenful is padded out to exactly the viewport height, so
/// نبذة عن شريك الحياة and everything after it start just BELOW the fold —
/// the user has to scroll to reach them, and the action buttons sit over empty
/// paper rather than over text.
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
  /// screenful is padded to exactly this, which is what puts the fold between
  /// نبذة عني and نبذة عن شريك الحياة.
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

  @override
  void dispose() {
    _atTop.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    final pixels = notification.metrics.pixels;
    widget.scrollOffset.value = pixels < 0 ? 0 : pixels;
    _atTop.value = pixels <= 0.5;
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
                    SliverToBoxAdapter(child: _firstScreenful()),
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

  /// Photo + نبذة عني, padded out to a full viewport.
  ///
  /// `minHeight` on a `mainAxisSize.min` Column makes the column at least a
  /// screen tall while its children still lay out from the top, so the leftover
  /// becomes empty paper under نبذة عني — the "spacer" that keeps the action
  /// buttons off the text and pushes the partner sections below the fold. A
  /// long نبذة simply grows past it instead of overflowing.
  Widget _firstScreenful() {
    return ColoredBox(
      color: QeranColors.paper,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: widget.viewportHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The photo is expensive to raster (sigma blur) and it scrolls.
            // Boundaried so scrolling translates a cached layer instead of
            // re-blurring each frame.
            RepaintBoundary(
              child: DiscoveryImagePanel(
                profile: widget.profile,
                height: widget.photoHeight,
                onFilterTap: widget.onFilterTap,
              ),
            ),
            // Transform, not padding: it lifts the sheet over the photo's
            // bottom edge for the layered look without changing the column's
            // height, so the fold maths stays exact.
            Transform.translate(
              offset: const Offset(0, -DiscoveryMergedProfileBody.sheetOverlap),
              child: DiscoveryProfileIntroSheet(profile: widget.profile),
            ),
          ],
        ),
      ),
    );
  }
}
