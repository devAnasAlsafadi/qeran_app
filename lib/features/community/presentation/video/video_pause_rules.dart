import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'community_video_controller.dart';

/// What pauses a card's video (Q9): its tab hidden, a route or a sheet over
/// it, the app leaving the foreground, and a scroll that leaves less than half
/// of it in view — no sound from a video the member can't see (Anas,
/// 2026-10-04). The viewer holding it full screen is over it on purpose: it
/// plays on there. Nothing resumes on its own.
mixin VideoPauseRules<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  /// The card's controller, once it has one.
  @protected
  CommunityVideoController? get pausable;

  /// Under this share of the card in view, it pauses.
  static const double visibleShare = 0.5;

  ScrollPosition? _scroll;
  bool _measuring = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// A hidden tab or a route over this one pauses it.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shown =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    if (!shown) pauseHere();
    _follow(Scrollable.maybeOf(context)?.position);
  }

  void _follow(ScrollPosition? scroll) {
    if (scroll == _scroll) return;
    _scroll?.removeListener(_scrolled);
    _scroll = scroll?..addListener(_scrolled);
  }

  /// Measured once the scroll's frame is laid out.
  void _scrolled() {
    if (_measuring) return;
    _measuring = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measuring = false;
      if (mounted && _shareInView() < visibleShare) pauseHere();
    });
  }

  /// How much of the card its scroll view shows, 0 to 1.
  double _shareInView() {
    final card = context.findRenderObject();
    final view = Scrollable.maybeOf(context)?.context.findRenderObject();
    if (card is! RenderBox || view is! RenderBox || !card.hasSize) return 1;
    final rect = MatrixUtils.transformRect(
      card.getTransformTo(view),
      Offset.zero & card.size,
    );
    final seen = rect.intersect(Offset.zero & view.size);
    if (rect.isEmpty || seen.width <= 0 || seen.height <= 0) return 0;
    return seen.width * seen.height / (rect.width * rect.height);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_leavesForeground(state)) pausable?.suspend();
  }

  /// Android leaves at `hidden` / `paused`; iOS already at `inactive` (D12,
  /// the privacy shield's rule).
  static bool _leavesForeground(AppLifecycleState state) =>
      state == AppLifecycleState.paused ||
      state == AppLifecycleState.hidden ||
      (state == AppLifecycleState.inactive &&
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Pauses it, unless the viewer holds it.
  @protected
  void pauseHere() {
    final c = pausable;
    if (c != null && !c.handedOver) c.suspend();
  }

  @override
  void dispose() {
    _follow(null);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
