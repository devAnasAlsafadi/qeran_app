import 'dart:async';

import 'package:flutter/widgets.dart';

/// The name of the route on top of the app's navigator, for code that has no
/// context to ask. C4 holds an expired session's sign-out until the splash
/// has routed: the splash reads the token once, and would otherwise route on
/// into the app after the sign-out.
class AppRouteTracker extends NavigatorObserver {
  /// The top route's name; null for an unnamed one (a dialog, a sheet).
  final ValueNotifier<String?> top = ValueNotifier<String?>(null);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      top.value = route.settings.name;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      top.value = previousRoute?.settings.name;

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) top.value = newRoute.settings.name;
  }

  /// Completes once [name] is no longer on top: at once if it isn't now.
  Future<void> whenNotOn(String name) {
    if (top.value != name) return Future<void>.value();
    final left = Completer<void>();
    void check() {
      if (top.value == name || left.isCompleted) return;
      top.removeListener(check);
      left.complete();
    }

    top.addListener(check);
    return left.future;
  }
}
