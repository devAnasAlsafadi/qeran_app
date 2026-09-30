import 'package:flutter/foundation.dart';

import '../../notifications/presentation/routing/notification_deep_link.dart';
import 'home_back_trail.dart';
import 'home_tab_switcher.dart';

/// How the user shell moves between its tabs by anything other than a plain
/// swipe of the stage: nav taps, notification links, and the back trails they
/// leave. The shell hands these to its tabs through `HomeShellScope`.
class HomeShellNavigator extends ChangeNotifier {
  HomeShellNavigator({
    required this.tabs,
    required this.markTabSeen,
    required this.openInbox,
    required this.openChat,
  });

  static const int communityTab = 0;
  static const int discoveryTab = 1;
  static const int likesTab = 2;
  static const int profileTab = 3;

  final HomeTabSwitcher tabs;

  /// Acknowledges a tab's badge.
  final ValueChanged<int> markTabSeen;

  /// Pushes the notifications inbox; completes with what the user tapped.
  final Future<Object?> Function() openInbox;

  /// Pushes the chat with the matchmaker.
  final VoidCallback openChat;

  HomeBackTrail? _backTrail;
  bool _disposed = false;

  /// Where the visible tab was reached FROM, when it was not simply tapped —
  /// see [openFromNotification]. Drives the destination's back control and the
  /// system back button alike.
  HomeBackTrail? get backTrail => _backTrail;

  /// The single entry point for BOTH notification paths — a row tapped in the
  /// inbox (handed back by `openNotifications`) and a system push tapped
  /// outside the app. A tab link switches the tab and raises the notifications
  /// [HomeBackTrail], which is what puts a back control on the destination.
  ///
  /// The trail is raised OUTSIDE the tab switch on purpose: the switch returns
  /// early when the target is already showing, and that is exactly the case
  /// where the control matters most — nothing else on screen changes, so it is
  /// the only sign the tap did anything.
  ///
  /// A chat link raises no trail: the chat is pushed, so its own back returns
  /// to whatever it covered.
  void openFromNotification(NotificationDeepLink link) {
    switch (link) {
      case NoDeepLink():
        return;
      case OpenMatchmakerChat():
        openChat();
      case OpenLikesTab():
        _setTrail(HomeBackTrail.notifications);
        openLikesTab();
      case OpenProfileTab():
        _setTrail(HomeBackTrail.notifications);
        openProfileTab();
    }
  }

  /// A manual bottom-nav tap ends the notification trail — otherwise the back
  /// control would sit there forever, pointing at an inbox the user has since
  /// navigated away from by hand.
  void onNavTap(int index) {
    _clearTrail();
    _selectTab(index);
  }

  void openLikesTab() => _selectTab(likesTab);

  void openProfileTab() => _selectTab(profileTab);

  /// Back for a tab that was never pushed onto. Both the top bar's control and
  /// the Android back button land here, so there is one behaviour rather than
  /// two.
  void followBackTrail() {
    switch (_backTrail) {
      case HomeBackTrail.notifications:
        _returnToNotifications();
      case null:
        break;
    }
  }

  /// Reopens the inbox and applies whatever the user taps there next — a fresh
  /// notification wins over the one that brought them here.
  ///
  /// Both the back arrow and the Android back button land here, so there is one
  /// behaviour rather than two. Clearing the trail is part of it: the trail is
  /// spent once it has been followed, and popping the inbox without tapping
  /// anything leaves the tab as an ordinary tab.
  Future<void> _returnToNotifications() async {
    _clearTrail();
    final result = await openInbox();
    if (_disposed || result is! NotificationDeepLink) return;
    openFromNotification(result);
  }

  /// Opening a tab acknowledges its badge. Ahead of the switch's early return
  /// on purpose: a live event can raise a dot on the tab already showing, and
  /// a visible dot that ignores a tap reads as broken.
  Future<void> _selectTab(int index) {
    markTabSeen(index);
    return tabs.select(index);
  }

  void _setTrail(HomeBackTrail trail) {
    if (_disposed) return;
    _backTrail = trail;
    notifyListeners();
  }

  void _clearTrail() {
    if (_backTrail == null) return;
    _backTrail = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
