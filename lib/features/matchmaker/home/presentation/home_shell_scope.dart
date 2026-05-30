import 'package:flutter/widgets.dart';

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

  const MatchmakerHomeShellScope({
    super.key,
    required this.openTab,
    required super.child,
  });

  /// Returns the nearest scope, or `null` when the caller is rendered
  /// outside the matchmaker shell. Callers should fall back gracefully.
  static MatchmakerHomeShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MatchmakerHomeShellScope>();

  @override
  bool updateShouldNotify(MatchmakerHomeShellScope oldWidget) => false;
}
