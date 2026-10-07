import 'package:firebase_messaging/firebase_messaging.dart';

/// The pushes she taps outside the app: each one while it runs in the
/// background, and the one that launched it. Firebase's in the app; a test
/// hands the shell its own.
class MatchmakerPushTaps {
  const MatchmakerPushTaps({required this.opened, required this.initial});

  /// Firebase's: background taps, and the cold-start one.
  factory MatchmakerPushTaps.firebase() => MatchmakerPushTaps(
    opened: FirebaseMessaging.onMessageOpenedApp,
    initial: () => FirebaseMessaging.instance.getInitialMessage(),
  );

  /// A push tapped while the app was alive.
  final Stream<RemoteMessage> opened;

  /// The push whose tap launched the app, if one did.
  final Future<RemoteMessage?> Function() initial;
}
