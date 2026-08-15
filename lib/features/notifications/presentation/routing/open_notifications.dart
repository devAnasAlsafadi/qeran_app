import 'package:flutter/material.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/features/home/presentation/home_shell_scope.dart';

import 'notification_deep_link.dart';

/// Opens the notifications inbox and applies any deep-link the user taps.
///
/// The inbox is pushed on top of the home shell, so it can't reach
/// [HomeShellScope] itself (a pushed route isn't a descendant of `HomeScreen`).
/// Instead the screen pops returning a [NotificationDeepLink]; this helper —
/// invoked from a caller that IS inside the shell (the discovery bell) — reads
/// the scope up front, awaits the intent, then hands it to the shell.
///
/// The shell owns what to do with it, so this path and the system-push path
/// share one implementation and cannot drift.
Future<void> openNotifications(BuildContext context) async {
  // Capture the shell BEFORE the await (no BuildContext use after the gap).
  final shell = HomeShellScope.maybeOf(context);
  // Untyped push: `onGenerateRoute` builds a `MaterialPageRoute<dynamic>`, so a
  // typed `pushNamed<NotificationDeepLink>` would throw on the route cast. The
  // screen pops a [NotificationDeepLink]; we type-check the result here.
  final result = await Navigator.of(context).pushNamed(RouteNames.notifications);

  if (shell == null || result is! NotificationDeepLink) return;
  shell.openFromNotification(result);
}
