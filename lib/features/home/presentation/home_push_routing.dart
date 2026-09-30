import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/notifications/presentation/routing/notification_deep_link.dart';

/// FCM deep-linking for the user shell. Confined to the shell — mirrors the
/// matchmaker shell (no main.dart bootstrap changes). Role-guarded so a
/// matchmaker-targeted push never acts on the user tree. The shell's SignalR
/// carries chat traffic only, so the foreground stream is what refreshes the
/// badges here.
class HomePushRouting {
  HomePushRouting({required this.onOpen, required this.onForegroundPush});

  /// A tapped push, resolved to where it points.
  final ValueChanged<NotificationDeepLink> onOpen;

  /// A push that arrived while the app was open. Never navigates.
  final VoidCallback onForegroundPush;

  StreamSubscription<RemoteMessage>? _tapSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  void start() {
    // Background-tap (app alive) + terminated/cold-start (launched by tap).
    _tapSub = FirebaseMessaging.onMessageOpenedApp.listen(_route);
    FirebaseMessaging.instance.getInitialMessage().then((m) {
      if (m != null) _route(m);
    });
    // Foreground push → refresh the unread indicators (no auto-navigation).
    _foregroundSub = FirebaseMessaging.onMessage.listen(
      (_) => onForegroundPush(),
    );
  }

  void dispose() {
    unawaited(_tapSub?.cancel());
    unawaited(_foregroundSub?.cancel());
  }

  /// Defensive role guard: only the regular user shell acts (a Moderator push
  /// routes elsewhere). Non-actionable payloads resolve to [NoDeepLink], which
  /// the shell ignores.
  void _route(RemoteMessage message) {
    final role = sl<UserSessionCubit>().currentUser?.role;
    if ((role ?? '').toLowerCase() == 'moderator') return;
    onOpen(NotificationDeepLinkRouter.resolveData(message.data));
  }
}
