import 'package:flutter/widgets.dart';

import '../../notifications/presentation/routing/notification_deep_link.dart';
import 'home_back_trail.dart';

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
///
/// Because none of these push anything, a destination reached this way has
/// nothing to pop — which is what [backTrail] and [followBackTrail] exist for.
class HomeShellScope extends InheritedWidget {
  /// Switch the bottom navigation to the Likes tab.
  final VoidCallback openLikesTab;

  /// Switch the bottom navigation to the Messages tab.
  ///
  /// [trail] records where the switch came from, so the tab can offer a way
  /// back. Omitted for a plain switch.
  final void Function({bool refresh, HomeBackTrail? trail}) openMessagesTab;

  /// Switch the bottom navigation to the Profile tab.
  final VoidCallback openProfileTab;

  /// Apply a notification deep-link: switch to its tab AND remember that the
  /// destination was reached from a notification, so it can offer a way back.
  ///
  /// Both notification paths funnel through here — a row tapped in the inbox
  /// (popped back to `openNotifications`) and a system push tapped outside the
  /// app — so they cannot drift apart.
  final void Function(NotificationDeepLink link) openFromNotification;

  /// Where the visible tab was reached FROM, or null when it was simply
  /// tapped. Cleared by the first manual bottom-nav tap — the trail is spent
  /// once the user navigates by hand.
  final HomeBackTrail? backTrail;

  /// Follow whichever trail is live, or do nothing when there is none.
  ///
  /// Deliberately NOT a pop for either trail: nothing was pushed. The inbox
  /// route is destroyed on the way to a tab (and never existed at all on the
  /// push path), and a tab switch leaves no route behind either — so "back"
  /// means reopening the inbox, or switching tabs again.
  final VoidCallback followBackTrail;

  const HomeShellScope({
    super.key,
    required this.openLikesTab,
    required this.openMessagesTab,
    required this.openProfileTab,
    required this.openFromNotification,
    required this.backTrail,
    required this.followBackTrail,
    required super.child,
  });

  /// Returns the nearest scope, or `null` when the caller is rendered
  /// outside the `HomeScreen` shell (widget tests, deep links from a
  /// notification, etc). Callers should fall back gracefully.
  static HomeShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeShellScope>();

  // Was unconditionally false while every field was a stable callback. It no
  // longer is: the tabs rebuild their back control off [backTrail].
  @override
  bool updateShouldNotify(HomeShellScope oldWidget) =>
      oldWidget.backTrail != backTrail;
}
