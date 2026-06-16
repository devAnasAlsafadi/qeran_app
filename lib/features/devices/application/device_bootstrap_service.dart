import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/services/device_info_service.dart';
import 'package:qeran/core/services/language_service.dart';
import 'package:qeran/core/services/notification_service.dart';
import 'package:qeran/core/services/storage_service.dart';

import '../domain/usecases/link_device_usecase.dart';
import '../domain/usecases/register_device_usecase.dart';
import '../domain/usecases/unlink_device_usecase.dart';

/// Single entry point used by Splash + auth blocs + locale changes to drive
/// the FCM/Devices lifecycle. All public methods are fire-and-forget — they
/// catch all errors, log them, and never throw.
class DeviceBootstrapService {
  final NotificationService _notifications;
  final DeviceInfoService _deviceInfo;
  final RegisterDeviceUseCase _registerDevice;
  final LinkDeviceUseCase _linkDevice;
  final UnlinkDeviceUseCase _unlinkDevice;
  final SharedPrefService _sharedPrefs;
  final StorageService _secureStorage;
  final LanguageService _language;

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
  }) : _notifications = notifications,
       _deviceInfo = deviceInfo,
       _registerDevice = registerDevice,
       _linkDevice = linkDevice,
       _unlinkDevice = unlinkDevice,
       _sharedPrefs = sharedPrefs,
       _secureStorage = secureStorage,
       _language = language;

  /// First call site: Splash. Requests permission (once), retrieves the FCM
  /// token, registers if needed, links if a JWT is already in storage.
  Future<void> bootstrap() async {
    if (_busy) return;
    _busy = true;
    try {
      await _ensurePermission();
      final token = await _notifications.getToken();
      if (token == null) return;
      await _sharedPrefs.save(StorageKeys.latestFcmToken, token);
      await _registerIfNeeded(token);
      await _linkIfAuthenticated(token, force: false);
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
      final token = await _readOrFetchToken();
      if (token == null) return;
      await _linkIfAuthenticated(token, force: force);
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
      final token = await _readOrFetchToken();
      if (token == null) return;
      final result = await _unlinkDevice(token: token);
      result.fold(
        (failure) =>
            AppLogger.warning('unlink failed: ${failure.message}', tag: 'DEVICE'),
        (_) => AppLogger.info('Device unlinked', tag: 'DEVICE'),
      );
    } catch (e, s) {
      AppLogger.error('unlinkSilently failed', error: e, stack: s, tag: 'DEVICE');
    }
  }

  /// Wired into FirebaseMessaging.onTokenRefresh.
  Future<void> onTokenRefreshed(String newToken) async {
    try {
      AppLogger.info('Handling token refresh', tag: 'DEVICE');
      await _sharedPrefs.save(StorageKeys.latestFcmToken, newToken);
      await _sharedPrefs.remove(StorageKeys.lastRegisteredFcm);
      await _sharedPrefs.remove(StorageKeys.lastLinkedFcm);
      await _sharedPrefs.save(StorageKeys.deviceRegistered, false);
      await _registerIfNeeded(newToken);
      await _linkIfAuthenticated(newToken, force: true);
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
      final token = await _readOrFetchToken();
      if (token == null) return;
      await _registerIfNeeded(token, overrideLanguage: languageCode);
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

  Future<String?> _readOrFetchToken() async {
    final cached = await _sharedPrefs.get<String>(StorageKeys.latestFcmToken);
    if (cached != null && cached.isNotEmpty) return cached;
    final fresh = await _notifications.getToken();
    if (fresh != null) {
      await _sharedPrefs.save(StorageKeys.latestFcmToken, fresh);
    }
    return fresh;
  }

  Future<void> _registerIfNeeded(
    String token, {
    String? overrideLanguage,
  }) async {
    final language = overrideLanguage ?? _language.currentLanguage;
    final lastFcm = await _sharedPrefs.get<String>(
      StorageKeys.lastRegisteredFcm,
    );
    final lastLang = await _sharedPrefs.get<String>(
      StorageKeys.lastRegisteredLang,
    );
    final registered =
        await _sharedPrefs.get<bool>(StorageKeys.deviceRegistered) ?? false;
    if (registered && lastFcm == token && lastLang == language) return;

    final meta = await _deviceInfo.resolve();
    final result = await _registerDevice(
      token: token,
      deviceType: meta.deviceType,
      language: language,
      deviceName: meta.deviceName,
      deviceModel: meta.deviceModel,
      osVersion: meta.osVersion,
      appVersion: meta.appVersion,
    );
    await result.fold(
      (failure) async {
        AppLogger.error('register failed: ${failure.message}', tag: 'DEVICE');
      },
      (_) async {
        AppLogger.info('Device registered ($language)', tag: 'DEVICE');
        await _sharedPrefs.save(StorageKeys.deviceRegistered, true);
        await _sharedPrefs.save(StorageKeys.lastRegisteredFcm, token);
        await _sharedPrefs.save(StorageKeys.lastRegisteredLang, language);
      },
    );
  }

  Future<void> _linkIfAuthenticated(
    String token, {
    required bool force,
  }) async {
    final jwt = await _secureStorage.get<String>(StorageKeys.token);
    if (jwt == null || jwt.isEmpty) return;
    if (!force) {
      final lastLinked = await _sharedPrefs.get<String>(
        StorageKeys.lastLinkedFcm,
      );
      if (lastLinked == token) return;
    }

    final result = await _linkDevice(token: token);
    await result.fold(
      (failure) async => _onLinkFailed(failure, token),
      (_) async {
        AppLogger.info('Device linked', tag: 'DEVICE');
        await _sharedPrefs.save(StorageKeys.lastLinkedFcm, token);
      },
    );
  }

  Future<void> _onLinkFailed(Failure failure, String token) async {
    final msg = failure.message.toLowerCase();
    final notRegistered =
        msg.contains('device not found') || msg.contains('register it first');
    if (!notRegistered) {
      AppLogger.error('link failed: ${failure.message}', tag: 'DEVICE');
      return;
    }
    AppLogger.warning(
      'link reported device not registered — re-registering',
      tag: 'DEVICE',
    );
    await _sharedPrefs.save(StorageKeys.deviceRegistered, false);
    await _sharedPrefs.remove(StorageKeys.lastRegisteredFcm);
    await _registerIfNeeded(token);
    final retry = await _linkDevice(token: token);
    retry.fold(
      (f) => AppLogger.error('link retry failed: ${f.message}', tag: 'DEVICE'),
      (_) async {
        AppLogger.info('Device  linked (after register retry)', tag: 'DEVICE');
        await _sharedPrefs.save(StorageKeys.lastLinkedFcm, token);
      },
    );
  }
}
