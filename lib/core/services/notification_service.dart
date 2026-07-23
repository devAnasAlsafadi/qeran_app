import 'package:firebase_messaging/firebase_messaging.dart';

import '../app_logger.dart';

/// Thin wrapper around FirebaseMessaging used by the devices feature.
///
/// Holds no business logic — only IO. Permission/token retrieval/refresh
/// listening. Errors are logged and swallowed; callers must never block UX
/// on this service.
class NotificationService {
  FirebaseMessaging? _messaging;
  final List<Duration> _tokenRetryDelays;
  final Future<void> Function(Duration) _delay;
  Future<String?>? _tokenRequest;

  NotificationService({
    FirebaseMessaging? messaging,
    List<Duration> tokenRetryDelays = const [
      Duration(milliseconds: 400),
      Duration(milliseconds: 1200),
    ],
    Future<void> Function(Duration)? delay,
  }) : _messaging = messaging,
       _tokenRetryDelays = tokenRetryDelays,
       _delay = delay ?? Future<void>.delayed;

  FirebaseMessaging get _client => _messaging ??= FirebaseMessaging.instance;

  void Function(String token)? _onTokenRefresh;

  /// One-time bootstrap. Sets foreground presentation options on iOS and
  /// wires the token-refresh listener. Safe to call multiple times.
  Future<void> init({void Function(String token)? onTokenRefresh}) async {
    _onTokenRefresh = onTokenRefresh;
    try {
      await _client.setForegroundNotificationPresentationOptions(
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
    _client.onTokenRefresh.listen(
      (token) {
        AppLogger.info('FCM token refreshed', tag: 'FCM');
        _onTokenRefresh?.call(token);
      },
      onError: (Object e, StackTrace s) => AppLogger.error(
        'onTokenRefresh stream error',
        error: e,
        stack: s,
        tag: 'FCM',
      ),
    );
  }

  /// Requests notification permission. Returns `true` if authorized
  /// (provisional counts as authorized for delivery).
  Future<bool> requestPermission() async {
    try {
      final settings = await _client.requestPermission(
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
  /// (e.g. iOS before APNs is ready). Concurrent callers share one request,
  /// and transient Play Services failures get two short background retries.
  Future<String?> getToken() {
    final existing = _tokenRequest;
    if (existing != null) return existing;

    late final Future<String?> request;
    request = _getTokenWithRetry().whenComplete(() {
      if (identical(_tokenRequest, request)) _tokenRequest = null;
    });
    _tokenRequest = request;
    return request;
  }

  Future<String?> _getTokenWithRetry() async {
    Object? lastError;
    StackTrace? lastStack;
    final attempts = _tokenRetryDelays.length + 1;

    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        final token = await _client.getToken();
        if (token != null && token.isNotEmpty) return token;
      } catch (e, s) {
        lastError = e;
        lastStack = s;
      }

      if (attempt < _tokenRetryDelays.length) {
        await _delay(_tokenRetryDelays[attempt]);
      }
    }

    AppLogger.warning(
      'FCM token unavailable after $attempts attempt(s)'
      '${lastError == null ? '' : ': $lastError'}',
      tag: 'FCM',
    );
    if (lastStack != null) {
      AppLogger.debug(lastStack.toString(), tag: 'FCM');
    }
    return null;
  }

  /// Used only on account-delete (out of scope here, but exposed for the
  /// future cleanup path).
  Future<void> deleteToken() async {
    try {
      await _client.deleteToken();
      AppLogger.info('FCM token deleted', tag: 'FCM');
    } catch (e, s) {
      AppLogger.error('deleteToken failed', error: e, stack: s, tag: 'FCM');
    }
  }
}
