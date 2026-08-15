import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Whether the shell's bottom nav is currently on screen.
///
/// Published above the tab bodies so bottom-anchored chrome INSIDE a tab (the
/// chat composer) can step aside while the island is up and take the full
/// screen once it slides away. Absent — [maybeOf] returns null — on any route
/// pushed above the shell, which has no nav to avoid.
class BottomNavVisibility extends InheritedWidget {
  const BottomNavVisibility({
    super.key,
    required this.visible,
    required super.child,
  });

  final bool visible;

  static bool? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<BottomNavVisibility>()
      ?.visible;

  @override
  bool updateShouldNotify(BottomNavVisibility old) => old.visible != visible;
}

/// Shell scaffold whose bottom nav slides out of the way while the reader
/// scrolls down and returns on the first upward scroll. Shared by the user and
/// matchmaker shells so the two can never drift apart again.
///
/// Owns the two geometry decisions both shells must agree on:
///
///  * **`extendBody: true`** — the nav is a floating island over the content,
///    not a band carved out of it. With `false` the Scaffold reserves the nav's
///    whole footprint and the un-painted part of that band shows the scaffold
///    background as a coloured strip the content cannot pass behind. That is
///    the drift `1b454f9` introduced in the user shell.
///  * **The hide is a TRANSLATION, never a size change.** Collapsing the nav's
///    height (the previous `AnimatedSize` + `SizedBox.shrink`) re-laid out the
///    body on every animation frame. Sliding paints it away and leaves every
///    descendant's geometry untouched.
///
/// Tab bodies keep their own `QeranBottomNav.contentClearance` bottom padding —
/// that is what lets content scroll UNDER the island, and it is independent of
/// this widget.
class ScrollHidingNavScaffold extends StatefulWidget {
  const ScrollHidingNavScaffold({
    super.key,
    required this.currentIndex,
    required this.body,
    required this.navBuilder,
  });

  /// The selected tab. A change reveals the nav — see [_revealOnTabChange].
  final int currentIndex;

  final Widget body;

  /// Built fresh on every rebuild, deliberately: `BottomChromeInset` inside the
  /// nav re-measures its own footprint from `didUpdateWidget`, which never
  /// fires for a child widget handed down as the same instance. A builder keeps
  /// the toast host's clearance honest as the island slides.
  final WidgetBuilder navBuilder;

  /// Shared by the island and by any chrome stepping aside for it, so the two
  /// always travel together. 220 ms read as a snap rather than a glide on a
  /// surface this large — the island is the full width of the screen, and a
  /// short duration on a big travel distance is what makes motion feel abrupt.
  static const Duration duration = Duration(milliseconds: 300);
  static const Curve curve = Curves.easeOutCubic;

  @override
  State<ScrollHidingNavScaffold> createState() =>
      _ScrollHidingNavScaffoldState();
}

class _ScrollHidingNavScaffoldState extends State<ScrollHidingNavScaffold> {
  bool _visible = true;

  @override
  void didUpdateWidget(ScrollHidingNavScaffold old) {
    super.didUpdateWidget(old);
    _revealOnTabChange(old);
  }

  /// A tab switch always restores the nav. The destination keeps its own scroll
  /// offset, so a user who left tab A scrolled-down would land on tab B with no
  /// nav and no gesture that brings it back short of scrolling B itself.
  void _revealOnTabChange(ScrollHidingNavScaffold old) {
    if (widget.currentIndex != old.currentIndex) _setVisible(true);
  }

  void _setVisible(bool value) {
    if (_visible == value || !mounted) return;
    setState(() => _visible = value);
  }

  /// Horizontal scrollables (chip rows, the discovery deck's swipe) are ignored
  /// via the axis check — only a vertical read should move the nav.
  bool _onUserScroll(UserScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    switch (notification.direction) {
      case ScrollDirection.forward:
        _setVisible(true);
      case ScrollDirection.reverse:
        _setVisible(false);
      case ScrollDirection.idle:
        break;
    }
    // Never absorbed: nested scrollables and any other listener above must
    // still see the notification.
    return false;
  }

  /// Re-measures the settled island. The slide is a paint transform, so the
  /// footprint `BottomChromeInset` publishes is only correct once the animation
  /// stops; rebuilding here runs [ScrollHidingNavScaffold.navBuilder] again and
  /// the inset is re-registered from the final geometry.
  void _remeasureSettledNav() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: NotificationListener<UserScrollNotification>(
        onNotification: _onUserScroll,
        child: BottomNavVisibility(visible: _visible, child: widget.body),
      ),
      bottomNavigationBar: AnimatedSlide(
        // A full-height translation down — the island leaves the screen without
        // its layout box ever changing size.
        offset: _visible ? Offset.zero : const Offset(0, 1),
        duration: ScrollHidingNavScaffold.duration,
        curve: ScrollHidingNavScaffold.curve,
        onEnd: _remeasureSettledNav,
        child: widget.navBuilder(context),
      ),
    );
  }
}
