import 'package:flutter/widgets.dart';

import '../../shared/data/matchmaker_notification_router.dart';
import '../../users/domain/entities/matchmaker_users_list.dart';

/// Switches the matchmaker bottom-nav tab at [index], optionally
/// targeting a Users sub-tab when [index] is the Users tab.
typedef MatchmakerOpenTab = void Function(
  int index, {
  MatchmakerUsersList? usersSubTab,
});

/// Inherited handle exposed by `MatchmakerHomeScreen` so descendants
/// can switch the bottom-nav tab (and a Users sub-tab) without pushing
/// a new route.
///
/// Mirrors the user-side `HomeShellScope` shape so consumers feel
/// identical regardless of role. Used by the dashboard stat cards to
/// jump to the right destination (e.g. pending count → Users / pending).
class MatchmakerHomeShellScope extends InheritedWidget {
  /// Switch the bottom navigation to the tab at [index].
  /// Index follows the order defined in `MatchmakerHomeScreen`
  /// (0=dashboard, 1=users, 2=compat cases, 3=conversations, 4=explore).
  final MatchmakerOpenTab openTab;

  /// Apply a notification deep-link: switch to its destination AND remember
  /// that it was reached from a notification, so the destination can offer a
  /// way back. Both notification paths funnel through here — a row tapped in
  /// the inbox and a system push tapped outside the app.
  final void Function(MatchmakerDeepLink link) openFromNotification;

  /// True while the visible tab was reached from a notification. Cleared by the
  /// first manual bottom-nav tap.
  final bool fromNotification;

  /// Reopen the inbox. NOT a pop — the inbox pops itself on the way to a tab,
  /// and never existed when the push came from outside the app, so there is
  /// nothing below to pop back to.
  final VoidCallback returnToNotifications;

  const MatchmakerHomeShellScope({
    super.key,
    required this.openTab,
    required this.openFromNotification,
    required this.fromNotification,
    required this.returnToNotifications,
    required super.child,
  });

  /// Returns the nearest scope, or `null` when the caller is rendered
  /// outside the matchmaker shell. Callers should fall back gracefully.
  static MatchmakerHomeShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MatchmakerHomeShellScope>();

  // Was unconditionally false while every field was a stable callback. The
  // tabs now rebuild their back control off [fromNotification].
  @override
  bool updateShouldNotify(MatchmakerHomeShellScope oldWidget) =>
      oldWidget.fromNotification != fromNotification;
}
