import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

import '../../domain/entities/discovery_profile.dart';
import '../blocs/discovery_cubit.dart';
import 'discovery_card.dart';
import 'discovery_deck_animator.dart';
import 'discovery_merged_profile_body.dart';
import 'discovery_swipe_handler.dart';

/// How fast the empty paper under نبذة عني gives way, per pixel scrolled.
///
/// 1.0 would let the gap merely travel down the page with the content, which
/// is what made it read as dead space; at 2.0 it is spent within about half a
/// flick and the partner sections dock straight under the chips. The photo and
/// نبذة still track the finger exactly — only the gap moves at this rate.
const double _kFoldCollapseRate = 2.0;

/// Scroll distance over which the compatibility pill fades onto the photo.
///
/// It is deliberately absent at rest: the first thing the card shows is the
/// person, and a percentage next to their name reads as a verdict before the
/// user has read anything. Scrolling into the profile is the moment it becomes
/// useful, so that is when it arrives.
const double _kMatchPillRevealDistance = 90.0;

/// The merged discovery surface for ONE profile: a single full-bleed scroll
/// whose first screenful is the photo plus نبذة عني, and whose continuation is
/// the rest of the profile, inline.
///
/// At rest the first screenful measures exactly one viewport, so
/// نبذة عن شريك الحياة and everything after it start just BELOW the fold —
/// the user has to scroll to reach them, and the action buttons sit over empty
/// paper rather than over text. That surplus then collapses as the user
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
  /// screenful measures exactly this at rest, which is what puts the fold
  /// between نبذة عني and نبذة عن شريك الحياة.
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

  /// Photo + نبذة عني, held to a full viewport at rest and giving that surplus
  /// back as the user scrolls.
  ///
  /// `minHeight` on a `mainAxisSize.min` Column makes the column at least a
  /// screen tall while its children still lay out from the top, so the leftover
  /// becomes empty paper under نبذة عني — that is what keeps the action buttons
  /// off the text and puts نبذة عن شريك الحياة below the fold. A long نبذة
  /// simply grows past it instead of overflowing.
  ///
  /// The surplus is NOT a fixed spacer: it shrinks with the scroll (at
  /// [_kFoldCollapseRate]× the scroll distance), so the empty paper closes up
  /// instead of travelling down the page ahead of the content. The photo and
  /// نبذة still move 1:1 with the finger; only the sections below rise faster,
  /// docking flush under the chips once the surplus is spent. From there on
  /// everything scrolls normally.
  Widget _firstScreenful() {
    return ColoredBox(
      color: QeranColors.paper,
      child: ValueListenableBuilder<double>(
        valueListenable: widget.scrollOffset,
        // The column is built once and passed through — a scroll re-runs the
        // ConstrainedBox only, never the blurred photo.
        builder: (context, offset, child) => ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(
              0,
              widget.viewportHeight - offset * _kFoldCollapseRate,
            ),
          ),
          child: child,
        ),
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
                // The intro sheet slides up over the photo's bottom edge, so
                // the chips have to clear that overlap — plus room to breathe
                // — or the sheet slices through them.
                bottomContentInset:
                    DiscoveryMergedProfileBody.sheetOverlap + QeranSpacing.s16,
                matchPillReveal: _pillReveal,
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
