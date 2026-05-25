import 'package:firebase_messaging/firebase_messaging.dart';

import '../app_logger.dart';

/// Thin wrapper around FirebaseMessaging used by the devices feature.
///
/// Holds no business logic — only IO. Permission/token retrieval/refresh
/// listening. Errors are logged and swallowed; callers must never block UX
/// on this service.
class NotificationService {
  final FirebaseMessaging _messaging;

  NotificationService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  void Function(String token)? _onTokenRefresh;

  /// One-time bootstrap. Sets foreground presentation options on iOS and
  /// wires the token-refresh listener. Safe to call multiple times.
  Future<void> init({void Function(String token)? onTokenRefresh}) async {
    _onTokenRefresh = onTokenRefresh;
    try {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e, s) {
      AppLogger.warning(
        'setForegroundNotificationPresentationOptions failed: $e',
        tag: 'FCM',
      );
      AppLogger.debug(s.toString(), tag: 'FCM');
    }
    _messaging.onTokenRefresh.listen(
      (token) {
        AppLogger.info('FCM token refreshed', tag: 'FCM');
        _onTokenRefresh?.call(token);
      },
      onError: (Object e, StackTrace s) =>
          AppLogger.error('onTokenRefresh stream error',
              error: e, stack: s, tag: 'FCM'),
    );
  }

  /// Requests notification permission. Returns `true` if authorized
  /// (provisional counts as authorized for delivery).
  Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      AppLogger.info(
        'Notification permission: ${settings.authorizationStatus}',
        tag: 'FCM',
      );
      return granted;
    } catch (e, s) {
      AppLogger.error(
        'requestPermission failed',
        error: e,
        stack: s,
        tag: 'FCM',
      );
      return false;
    }
  }

  /// Returns the current FCM token, or `null` if not yet available
  /// (e.g. iOS before APNs is ready).
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        AppLogger.warning('FCM getToken returned null/empty', tag: 'FCM');
        return null;
      }
      return token;
    } catch (e, s) {
      AppLogger.error('getToken failed', error: e, stack: s, tag: 'FCM');
      return null;
    }
  }

  /// Used only on account-delete (out of scope here, but exposed for the
  /// future cleanup path).
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      AppLogger.info('FCM token deleted', tag: 'FCM');
    } catch (e, s) {
      AppLogger.error('deleteToken failed', error: e, stack: s, tag: 'FCM');
    }
  }
}
