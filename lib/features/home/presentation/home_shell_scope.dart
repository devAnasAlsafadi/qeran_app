import 'package:flutter/widgets.dart';

/// Inherited handle exposed by `HomeScreen` so descendants can switch
/// the bottom-nav tab without pushing a new route.
///
/// Consumers:
/// * The Stage-2 Match card's "Contact the matchmaker" CTA inside Likes —
///   switches to the Messages tab instead of pushing a placeholder chat
///   screen, so the `ChatEntryScreen` cubit state survives the navigation.
/// * The notifications inbox deep-link router — a tapped row switches to the
///   tab its `data.screen` points at (Likes / Messages / Profile) rather than
///   pushing a route, keeping every destination inside the shell.
class HomeShellScope extends InheritedWidget {
  /// Switch the bottom navigation to the Likes tab.
  final VoidCallback openLikesTab;

  /// Switch the bottom navigation to the Messages tab.
  final void Function({bool refresh}) openMessagesTab;

  /// Switch the bottom navigation to the Profile tab.
  final VoidCallback openProfileTab;

  const HomeShellScope({
    super.key,
    required this.openLikesTab,
    required this.openMessagesTab,
    required this.openProfileTab,
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
