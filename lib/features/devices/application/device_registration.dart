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

  /// The cached token, or a fresh one from FCM (then cached).
  Future<String?> readOrFetchToken() async {
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
