import 'dart:math' as math;

import 'package:flutter/material.dart';

/// How much of the screen's bottom edge is occupied by fixed chrome right now.
///
/// Exists because the toast host is mounted in `MaterialApp.builder`, ABOVE the
/// Navigator — deliberately, so a toast survives a route pop. That placement
/// makes the two obvious mechanisms unusable: `ScaffoldMessenger` only avoids
/// chrome for a host INSIDE the Scaffold, and an `InheritedWidget` published by
/// a screen cannot be read by an ancestor. A global notifier is the one channel
/// that crosses the boundary.
///
/// The host never learns which route is showing. Each piece of chrome declares
/// only its own footprint by wrapping itself in [BottomChromeInset]; the host
/// clears the largest live declaration. New bottom chrome opts in the same way,
/// with nothing central to edit.
class BottomChromeInsets {
  const BottomChromeInsets._();

  /// The tallest live declaration, in logical pixels measured up from the
  /// screen's bottom edge. Device insets are INCLUDED — a declaration is the
  /// full band to keep clear, not an amount to add to the safe area.
  static final ValueNotifier<double> clearance = ValueNotifier<double>(0);

  static final Map<Object, double> _entries = <Object, double>{};
  static bool _recomputeScheduled = false;

  static void _register(Object key, double height) {
    if (_entries[key] == height) return;
    _entries[key] = height;
    _scheduleRecompute();
  }

  static void _unregister(Object key) {
    if (_entries.remove(key) == null) return;
    _scheduleRecompute();
  }

  /// Always deferred to after the frame. Chrome registers from `initState` and
  /// withdraws from `dispose`, both of which run inside a build/teardown pass —
  /// notifying the host's [ValueListenableBuilder] there would mark it dirty
  /// during a build. One frame of stale clearance during a route change is
  /// invisible; a `setState() called during build` crash is not.
  static void _scheduleRecompute() {
    if (_recomputeScheduled) return;
    _recomputeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recomputeScheduled = false;
      clearance.value = _entries.values.fold<double>(0, math.max);
    });
  }

  @visibleForTesting
  static void debugReset() {
    _entries.clear();
    _recomputeScheduled = false;
    clearance.value = 0;
  }
}

/// Declares that its subtree is fixed chrome at the bottom of the screen, so
/// bottom-anchored overlays can sit clear of it.
///
/// Lays nothing out — [child] is built unchanged. Wrap the chrome itself (the
/// nav, an action bar) rather than the screen, so the footprint travels with
/// the component.
///
/// The footprint is MEASURED from the laid-out child, not passed in. Declaring
/// it arithmetically was tried and is wrong twice over:
///
///  * `QeranBottomNav.contentClearance` is the inset a *scrollable* needs, and
///    deliberately excludes `bMargin` so content scrolls under the floating
///    island. As a footprint it under-reports by 16px.
///  * A tab body is already inset above the nav by the Scaffold, so chrome
///    positioned inside it (the discovery action cluster) has its `bottom:`
///    measured from the body, not the screen — under-reporting by the nav's
///    whole height again.
///
/// Both are invisible in the arithmetic and obvious in the geometry, so the
/// geometry is the source of truth.
class BottomChromeInset extends StatefulWidget {
  final Widget child;

  const BottomChromeInset({super.key, required this.child});

  @override
  State<BottomChromeInset> createState() => _BottomChromeInsetState();
}

class _BottomChromeInsetState extends State<BottomChromeInset> {
  @override
  void initState() {
    super.initState();
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(BottomChromeInset old) {
    super.didUpdateWidget(old);
    // Rotation, a nav animating, or the cluster's backdrop fading all rebuild
    // through here; re-measure rather than let the host clear a stale band.
    _scheduleMeasure();
  }

  /// Runs after layout — the render box has no geometry before it.
  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize || !box.attached) return;
      final top = box.localToGlobal(Offset.zero).dy;
      final screenHeight = MediaQuery.sizeOf(context).height;
      BottomChromeInsets._register(this, screenHeight - top);
    });
  }

  @override
  void dispose() {
    BottomChromeInsets._unregister(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
