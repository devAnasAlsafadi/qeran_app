import 'package:flutter/widgets.dart';

/// Inherited handle exposed by `MatchmakerHomeScreen` so descendants
/// can switch the bottom-nav tab without pushing a new route.
///
/// Mirrors the user-side `HomeShellScope` shape so consumers (e.g. a
/// compatibility-case detail wanting to jump to the matchmaker–user
/// chat tab) feel identical regardless of role.
class MatchmakerHomeShellScope extends InheritedWidget {
  /// Switch the bottom navigation to the tab at [index].
  /// Index follows the order defined in `MatchmakerHomeScreen`
  /// (0=dashboard, 1=users, 2=compat cases, 3=conversations, 4=explore).
  final ValueChanged<int> openTab;

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
