import 'package:flutter/widgets.dart';

/// Inherited handle exposed by `HomeScreen` so descendants can switch
/// the bottom-nav tab without pushing a new route.
///
/// Today's only consumer is the Stage-2 Match card's "Contact the
/// matchmaker" CTA inside Likes — it switches to the Messages tab
/// instead of pushing a placeholder chat screen, so the user's
/// `ChatEntryScreen` cubit state is preserved across the navigation.
class HomeShellScope extends InheritedWidget {
  /// Switch the bottom navigation to the Messages tab.
  final VoidCallback openMessagesTab;

  const HomeShellScope({
    super.key,
    required this.openMessagesTab,
    required super.child,
  });

  /// Returns the nearest scope, or `null` when the caller is rendered
  /// outside the `HomeScreen` shell (widget tests, deep links from a
  /// notification, etc). Callers should fall back gracefully.
  static HomeShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeShellScope>();

  @override
  bool updateShouldNotify(HomeShellScope oldWidget) => false;
}
