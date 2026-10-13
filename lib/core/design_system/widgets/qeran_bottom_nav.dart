import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/bottom_chrome_inset.dart';
import '../tokens/qeran_colors.dart';
import '../tokens/qeran_motion.dart';
import '../tokens/qeran_radii.dart';
import '../tokens/qeran_typography.dart';
import 'qeran_nav_item.dart';

export 'qeran_nav_item.dart';

part 'qeran_bottom_nav_cells.dart';
part 'qeran_bottom_nav_island.dart';
part 'qeran_bottom_nav_landscape.dart';

/// The floating bottom navigation: a white island, one cell per tab, each an
/// icon over its label. The selected tab is marked in its own place — a gold
/// disc behind its icon, the icon filled and wine, the label wine and bold.
/// Nothing rises above the bar, so nothing is cut by its edges (run 8: the
/// lifted disc sat too high, and its halo was clipped on the end tabs).
///
/// One 640 ms ease-in-out controller moves the disc from tab to tab and
/// crossfades each cell's outline and filled icon, so a change reads as one
/// motion.
class QeranBottomNav extends StatefulWidget {
  final List<QeranNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const QeranBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  static const double totalHeight = 104;
  static const double barHeight = 70;

  /// The selected tab's disc: smaller than the lifted one it replaced (52.8),
  /// so it fits the bar with the label under it.
  static const double discDiameter = 40;

  /// From the bar's top edge to each cell's icon slot, a [discDiameter]
  /// square — so the disc sits exactly on the selected icon.
  static const double iconSlotTop = 7;
  static const double hMargin = 16;

  /// Gap between the island and the safe-area edge. Deliberately smaller than
  /// [hMargin]: the side margins have the whole screen width to breathe into,
  /// while this one stacks on top of the device's own bottom inset, so 16 here
  /// read as a hole under the bar rather than as float. Not 0 — the island has
  /// to keep reading as an island, not as a docked bar.
  static const double bMargin = 8;
  static const double compactLandscapeHeight = 64;
  static const double compactLandscapeMargin = 8;

  /// The island and the selected tab's disc, for tests.
  @visibleForTesting
  static const barKey = ValueKey('qeranNavBar');
  @visibleForTesting
  static const discKey = ValueKey('qeranNavDisc');

  /// Bottom inset a tab scrollable needs so its LAST item clears the floating
  /// island + the device gesture area, while items above still scroll under it.
  /// [totalHeight] ≈ bar + bottom margin + breathing; [viewPadding].bottom
  /// re-adds the home-indicator inset the tab body no longer reserves (its
  /// `SafeArea` drops `bottom`). Used as the scrollables' bottom padding.
  static double contentClearance(BuildContext context) {
    final media = MediaQuery.of(context);
    final isLandscape = media.size.width > media.size.height;
    return (isLandscape
            ? compactLandscapeHeight + compactLandscapeMargin
            : totalHeight) +
        media.viewPadding.bottom;
  }

  @override
  State<QeranBottomNav> createState() => _QeranBottomNavState();
}

class _QeranBottomNavState extends State<QeranBottomNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final CurvedAnimation _slide;
  late final ReverseAnimation _slideReverse;

  // Disc position lerps from _animFrom -> _animTo across the curve.
  // Doubles so a rapid mid-animation tap re-anchors from the LIVE
  // interpolated position (no snap-back).
  late double _animFrom;
  late double _animTo;
  late int _iconFrom;
  late int _iconTo;

  // Tabs that are neither the from nor the to of a transition show their
  // outline icon fully — share a single const animation.
  static const Animation<double> _staticVisible =
      AlwaysStoppedAnimation<double>(1.0);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: QeranMotion.hero, // 640 ms — deliberate, premium
    );
    _slide = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
    _slideReverse = ReverseAnimation(_slide);
    _animFrom = widget.currentIndex.toDouble();
    _animTo = widget.currentIndex.toDouble();
    _iconFrom = widget.currentIndex;
    _iconTo = widget.currentIndex;
    _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(QeranBottomNav old) {
    super.didUpdateWidget(old);
    if (widget.currentIndex != old.currentIndex) {
      final liveT = _slide.value;
      _animFrom = _animFrom + (_animTo - _animFrom) * liveT;
      _animTo = widget.currentIndex.toDouble();
      _iconFrom = _iconTo;
      _iconTo = widget.currentIndex;
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  /// Opacity of tab `i`'s outline icon; its filled icon takes the rest.
  /// — i == _iconTo  (becoming selected): 1 → 0 as the disc arrives
  /// — i == _iconFrom (leaving):          0 → 1 as the disc leaves
  /// — anything else: statically 1.0
  Animation<double> _outlineOpacityFor(int i) {
    if (i == _iconTo) return _slideReverse;
    if (i == _iconFrom) return _slide;
    return _staticVisible;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Declares the nav's own footprint so bottom-anchored overlays (the toast
    // host) sit above it. Wrapped HERE rather than at each shell, so both the
    // user and matchmaker shells get it from the one component, landscape
    // branch included.
    return BottomChromeInset(child: _buildNav(media));
  }

  Widget _buildNav(MediaQueryData media) {
    if (media.size.width > media.size.height) {
      return _CompactLandscapeNav(
        items: widget.items,
        currentIndex: widget.currentIndex,
        onTap: widget.onTap,
      );
    }
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          QeranBottomNav.hMargin,
          0,
          QeranBottomNav.hMargin,
          QeranBottomNav.bMargin,
        ),
        child: SizedBox(
          height: QeranBottomNav.totalHeight,
          child: LayoutBuilder(
            builder: (context, c) => AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) => _island(context, c.maxWidth),
            ),
          ),
        ),
      ),
    );
  }
}
