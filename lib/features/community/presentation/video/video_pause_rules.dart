import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'community_video_controller.dart';

/// What pauses a card's video (Q9): its tab hidden, a route or a sheet over
/// it, the app leaving the foreground. The viewer holding it full screen is
/// over it on purpose: it plays on there. Nothing resumes on its own.
mixin VideoPauseRules<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  /// The card's controller, once it has one.
  @protected
  CommunityVideoController? get pausable;

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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
