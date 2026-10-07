import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/blocs/user_session/user_session_cubit.dart';
import '../../shared/data/matchmaker_notification_router.dart';
import 'matchmaker_push_taps.dart';

/// FCM deep-linking (M4d), pulled out of her shell: a tapped push, parsed into
/// where it points. Confined to the shell — Moderator-only mount, zero
/// user-side impact. SignalR (4c) covers foreground live updates, so
/// foreground `onMessage` is intentionally NOT handled here.
class MatchmakerPushRouting {
  MatchmakerPushRouting({required this.onOpen, MatchmakerPushTaps? taps})
    : _taps = taps;

  /// A tapped push, resolved to where it points.
  final ValueChanged<MatchmakerDeepLink> onOpen;

  final MatchmakerPushTaps? _taps;
  StreamSubscription<RemoteMessage>? _tapSub;

  void start() {
    final taps = _taps ?? MatchmakerPushTaps.firebase();
    // Background-tap (app alive) + terminated/cold-start (launched by tap).
    _tapSub = taps.opened.listen(_route);
    taps.initial().then((m) {
      if (m != null) _route(m);
    });
  }

  void dispose() => unawaited(_tapSub?.cancel());

  /// Defensive role guard (the shell is Moderator-only anyway). Parsing and
  /// audience guards live in [MatchmakerNotificationRouter]; the shell only
  /// navigates.
  void _route(RemoteMessage message) {
    final role = sl<UserSessionCubit>().currentUser?.role;
    if ((role ?? '').toLowerCase() != 'moderator') return;
    onOpen(MatchmakerNotificationRouter.parse(message.data));
  }
}
