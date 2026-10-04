import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/services/storage_service.dart';

import '../domain/usecases/link_device_usecase.dart';
import '../domain/usecases/unlink_device_usecase.dart';
import 'device_registration.dart';

/// The account-level half of push: this device's token linked to the account
/// signed in, and unlinked when it leaves. Used by [DeviceBootstrapService];
/// never throws past it.
class DeviceAccountLink {
  final DeviceRegistration _registration;
  final LinkDeviceUseCase _linkDevice;
  final UnlinkDeviceUseCase _unlinkDevice;
  final SharedPrefService _sharedPrefs;
  final StorageService _secureStorage;

  DeviceAccountLink({
    required DeviceRegistration registration,
    required LinkDeviceUseCase linkDevice,
    required UnlinkDeviceUseCase unlinkDevice,
    required SharedPrefService sharedPrefs,
    required StorageService secureStorage,
  }) : _registration = registration,
       _linkDevice = linkDevice,
       _unlinkDevice = unlinkDevice,
       _sharedPrefs = sharedPrefs,
       _secureStorage = secureStorage;

  Future<void> linkIfAuthenticated(
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

  /// Unlinks [token] from the account signed in; logs the outcome.
  Future<void> unlink(String token) async {
    final result = await _unlinkDevice(token: token);
    result.fold(
      (failure) =>
          AppLogger.warning('unlink failed: ${failure.message}', tag: 'DEVICE'),
      (_) => AppLogger.info('Device unlinked', tag: 'DEVICE'),
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
    await _registration.registerIfNeeded(token);
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
