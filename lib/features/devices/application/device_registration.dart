import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/services/device_info_service.dart';
import 'package:qeran/core/services/language_service.dart';
import 'package:qeran/core/services/notification_service.dart';

import '../domain/usecases/register_device_usecase.dart';

/// This device's FCM token and its registration with the server: the
/// device-level half of push, whoever is signed in. The prefs markers say
/// what the server last saw, so a register runs only when something changed.
/// Used by [DeviceBootstrapService]; never throws past it.
class DeviceRegistration {
  final NotificationService _notifications;
  final DeviceInfoService _deviceInfo;
  final RegisterDeviceUseCase _registerDevice;
  final SharedPrefService _sharedPrefs;
  final LanguageService _language;

  DeviceRegistration({
    required NotificationService notifications,
    required DeviceInfoService deviceInfo,
    required RegisterDeviceUseCase registerDevice,
    required SharedPrefService sharedPrefs,
    required LanguageService language,
  }) : _notifications = notifications,
       _deviceInfo = deviceInfo,
       _registerDevice = registerDevice,
       _sharedPrefs = sharedPrefs,
       _language = language;

  /// A renewal under way ([renewToken]): token reads wait for it, so a
  /// sign-in meanwhile never links the token being deleted.
  Future<void> _renewal = Future<void>.value();

  /// How long FCM gets to delete the token before the renewal stops there.
  static const Duration _deleteWait = Duration(seconds: 10);

  /// What says which token the server last saw — forgotten with the token.
  static const List<String> _tokenKeys = [
    StorageKeys.latestFcmToken,
    StorageKeys.lastRegisteredFcm,
    StorageKeys.deviceRegistered,
  ];

  /// The cached token, or a fresh one from FCM (then cached).
  Future<String?> readOrFetchToken() async {
    await _renewal;
    return _readOrFetch();
  }

  /// Sign-out (A1): deletes this device's token with FCM, so nothing sent to
  /// it arrives any more, whoever it was linked to; then registers a new one,
  /// linked to no one until the next sign-in. Runs in the background and
  /// never throws. If FCM can't be reached the token stays, its markers
  /// forgotten: the next read registers it again.
  void renewToken() => _renewal = _renew();

  /// The release stays owed until FCM confirms the old token is gone (C2).
  Future<void> markReleaseOwed() =>
      _sharedPrefs.save(StorageKeys.pushReleaseOwed, true);

  /// Finishes a release an offline sign-out couldn't: waits out a renewal
  /// under way, then renews once more if it's still owed. Needs no JWT — FCM
  /// deletes the old token and a new one registers, unlinked.
  Future<void> retryOwedRelease() async {
    try {
      await _renewal;
      if (await _sharedPrefs.get<bool>(StorageKeys.pushReleaseOwed) != true) {
        return;
      }
      renewToken();
      await _renewal;
    } catch (e, s) {
      AppLogger.error('owed release failed', error: e, stack: s, tag: 'DEVICE');
    }
  }

  Future<void> _renew() async {
    try {
      final deleted = await Future.sync(_notifications.deleteToken)
          .then((_) => true)
          .timeout(_deleteWait, onTimeout: () => false)
          // A throw is "not deleted" too: the keys still go below, and the
          // owed release is retried (C2).
          .catchError((Object _) => false);
      for (final key in _tokenKeys) {
        await _sharedPrefs.remove(key);
      }
      if (!deleted) return;
      // The old token is dead: nothing of the old account reaches this phone.
      await _sharedPrefs.remove(StorageKeys.pushReleaseOwed);
      final fresh = await _readOrFetch();
      if (fresh != null) await registerIfNeeded(fresh);
    } catch (e, s) {
      AppLogger.error('renewToken failed', error: e, stack: s, tag: 'DEVICE');
    }
  }

  Future<String?> _readOrFetch() async {
    final cached = await _sharedPrefs.get<String>(StorageKeys.latestFcmToken);
    if (cached != null && cached.isNotEmpty) return cached;
    final fresh = await _notifications.getToken();
    if (fresh != null) {
      await _sharedPrefs.save(StorageKeys.latestFcmToken, fresh);
    }
    return fresh;
  }

  Future<void> registerIfNeeded(
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
}
