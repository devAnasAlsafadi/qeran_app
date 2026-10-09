import 'dart:async';

import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/services/device_info_service.dart';
import 'package:qeran/core/services/language_service.dart';
import 'package:qeran/core/services/notification_service.dart';
import 'package:qeran/core/services/storage_service.dart';

import '../domain/usecases/link_device_usecase.dart';
import '../domain/usecases/register_device_usecase.dart';
import '../domain/usecases/unlink_device_usecase.dart';
import 'device_account_link.dart';
import 'device_registration.dart';

/// Single entry point used by Splash + auth blocs + locale changes to drive
/// the FCM/Devices lifecycle. All public methods are fire-and-forget — they
/// catch all errors, log them, and never throw.
class DeviceBootstrapService {
  final NotificationService _notifications;
  final DeviceRegistration _registration;
  final DeviceAccountLink _account;
  final SharedPrefService _sharedPrefs;

  bool _busy = false;

  DeviceBootstrapService({
    required NotificationService notifications,
    required DeviceInfoService deviceInfo,
    required RegisterDeviceUseCase registerDevice,
    required LinkDeviceUseCase linkDevice,
    required UnlinkDeviceUseCase unlinkDevice,
    required SharedPrefService sharedPrefs,
    required StorageService secureStorage,
    required LanguageService language,
  }) : this._(
         notifications: notifications,
         sharedPrefs: sharedPrefs,
         registration: DeviceRegistration(
           notifications: notifications,
           deviceInfo: deviceInfo,
           registerDevice: registerDevice,
           sharedPrefs: sharedPrefs,
           language: language,
         ),
         linkDevice: linkDevice,
         unlinkDevice: unlinkDevice,
         secureStorage: secureStorage,
       );

  DeviceBootstrapService._({
    required NotificationService notifications,
    required SharedPrefService sharedPrefs,
    required DeviceRegistration registration,
    required LinkDeviceUseCase linkDevice,
    required UnlinkDeviceUseCase unlinkDevice,
    required StorageService secureStorage,
  }) : _notifications = notifications,
       _sharedPrefs = sharedPrefs,
       _registration = registration,
       _account = DeviceAccountLink(
         registration: registration,
         linkDevice: linkDevice,
         unlinkDevice: unlinkDevice,
         sharedPrefs: sharedPrefs,
         secureStorage: secureStorage,
       );

  /// First call site: Splash. Requests permission (once), retrieves the FCM
  /// token, registers if needed, links if a JWT is already in storage.
  Future<void> bootstrap() async {
    if (_busy) return;
    _busy = true;
    try {
      await _ensurePermission();
      await _registration.retryOwedRelease();
      final token = await _notifications.getToken();
      if (token == null) return;
      await _sharedPrefs.save(StorageKeys.latestFcmToken, token);
      await _registration.registerIfNeeded(token);
      await _account.linkIfAuthenticated(token, force: false);
    } catch (e, s) {
      AppLogger.error('bootstrap failed', error: e, stack: s, tag: 'DEVICE');
    } finally {
      _busy = false;
    }
  }

  /// Called by auth blocs after a fresh JWT is persisted. `force` bypasses the
  /// last-linked cache so a re-login on the same device always re-links.
  Future<void> linkSilently({bool force = true}) async {
    try {
      final token = await _registration.readOrFetchToken();
      if (token == null) return;
      await _account.linkIfAuthenticated(token, force: force);
    } catch (e, s) {
      AppLogger.error('linkSilently failed', error: e, stack: s, tag: 'DEVICE');
    }
  }

  /// Best-effort unlink of this device's push token — called during account
  /// deletion. Fire-and-forget: catches/logs, never throws. Reads the cached
  /// (or fresh) token; no-op when none. Local link markers are cleared by the
  /// full wipe, not here.
  Future<void> unlinkSilently() async {
    try {
      final token = await _registration.readOrFetchToken();
      if (token == null) return;
      await _account.unlink(token);
    } catch (e, s) {
      AppLogger.error('unlinkSilently failed', error: e, stack: s, tag: 'DEVICE');
    }
  }

  /// Sign-out (A1): the account leaving stops reaching this phone. Called
  /// while the account's token is still stored, since the server's unlink
  /// needs it, and waits [_unlinkWait] at most: offline the unlink fails at
  /// once, a slow one finishes on its own. Then the device's FCM token is
  /// renewed in the background ([DeviceRegistration.renewToken]), which
  /// holds even when the server never heard. Never throws.
  Future<void> releasePush() async {
    try {
      final token = await _sharedPrefs.get<String>(StorageKeys.latestFcmToken);
      if (token == null || token.isEmpty) return;
      await _registration.markReleaseOwed();
      await _account
          .unlink(token)
          .timeout(_unlinkWait)
          .catchError(
            (Object e) => AppLogger.warning('unlink: $e', tag: 'DEVICE'),
          );
      _registration.renewToken();
    } catch (e, s) {
      AppLogger.error('releasePush failed', error: e, stack: s, tag: 'DEVICE');
    }
  }

  static const Duration _unlinkWait = Duration(seconds: 3);

  /// Retries an owed push release whenever the connection returns (C2).
  StreamSubscription<bool> retryWhenOnline(Stream<bool> onStatusChange) =>
      onStatusChange
          .where((online) => online)
          .listen((_) => _registration.retryOwedRelease());

  /// Wired into FirebaseMessaging.onTokenRefresh.
  Future<void> onTokenRefreshed(String newToken) async {
    try {
      AppLogger.info('Handling token refresh', tag: 'DEVICE');
      await _sharedPrefs.save(StorageKeys.latestFcmToken, newToken);
      await _sharedPrefs.remove(StorageKeys.lastRegisteredFcm);
      await _sharedPrefs.remove(StorageKeys.lastLinkedFcm);
      await _sharedPrefs.save(StorageKeys.deviceRegistered, false);
      await _registration.registerIfNeeded(newToken);
      await _account.linkIfAuthenticated(newToken, force: true);
    } catch (e, s) {
      AppLogger.error(
        'onTokenRefreshed failed',
        error: e,
        stack: s,
        tag: 'DEVICE',
      );
    }
  }

  /// Called from `qeran_app.dart` when the active locale changes. Re-registers
  /// only when the language differs from what the server last saw, so widget
  /// rebuilds do not trigger spurious calls.
  Future<void> onLanguageChanged(String languageCode) async {
    try {
      final lastLang = await _sharedPrefs.get<String>(
        StorageKeys.lastRegisteredLang,
      );
      if (lastLang == languageCode) return;
      final token = await _registration.readOrFetchToken();
      if (token == null) return;
      await _registration.registerIfNeeded(token, overrideLanguage: languageCode);
    } catch (e, s) {
      AppLogger.error(
        'onLanguageChanged failed',
        error: e,
        stack: s,
        tag: 'DEVICE',
      );
    }
  }

  // ─── Internals ──────────────────────────────────────

  Future<void> _ensurePermission() async {
    final asked = await _sharedPrefs.get<bool>(
      StorageKeys.notifPermissionAsked,
    );
    if (asked == true) return;
    await _notifications.requestPermission();
    await _sharedPrefs.save(StorageKeys.notifPermissionAsked, true);
  }
}
