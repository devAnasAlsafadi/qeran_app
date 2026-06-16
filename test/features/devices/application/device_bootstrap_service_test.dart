import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/services/device_info_service.dart';
import 'package:qeran/core/services/language_service.dart';
import 'package:qeran/core/services/notification_service.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/features/devices/application/device_bootstrap_service.dart';
import 'package:qeran/features/devices/domain/usecases/link_device_usecase.dart';
import 'package:qeran/features/devices/domain/usecases/register_device_usecase.dart';
import 'package:qeran/features/devices/domain/usecases/unlink_device_usecase.dart';

class MockNotificationService extends Mock implements NotificationService {}

class MockDeviceInfoService extends Mock implements DeviceInfoService {}

class MockRegisterDeviceUseCase extends Mock
    implements RegisterDeviceUseCase {}

class MockLinkDeviceUseCase extends Mock implements LinkDeviceUseCase {}

class MockUnlinkDeviceUseCase extends Mock implements UnlinkDeviceUseCase {}

class MockSharedPrefService extends Mock implements SharedPrefService {}

class MockStorageService extends Mock implements StorageService {}

class MockLanguageService extends Mock implements LanguageService {}

void main() {
  late MockNotificationService notifications;
  late MockDeviceInfoService deviceInfo;
  late MockRegisterDeviceUseCase registerDevice;
  late MockLinkDeviceUseCase linkDevice;
  late MockUnlinkDeviceUseCase unlinkDevice;
  late MockSharedPrefService sharedPrefs;
  late MockStorageService secureStorage;
  late MockLanguageService language;
  late DeviceBootstrapService service;

  const tToken = 'fcm-token-1';
  const tJwt = 'jwt-1';

  setUp(() {
    notifications = MockNotificationService();
    deviceInfo = MockDeviceInfoService();
    registerDevice = MockRegisterDeviceUseCase();
    linkDevice = MockLinkDeviceUseCase();
    unlinkDevice = MockUnlinkDeviceUseCase();
    sharedPrefs = MockSharedPrefService();
    secureStorage = MockStorageService();
    language = MockLanguageService();

    // Permission flow defaults
    when(() => sharedPrefs.get<bool>(StorageKeys.notifPermissionAsked))
        .thenAnswer((_) async => true);
    when(() => sharedPrefs.save<bool>(any(), any()))
        .thenAnswer((_) async {});
    when(() => sharedPrefs.save<String>(any(), any()))
        .thenAnswer((_) async {});
    when(() => sharedPrefs.remove(any())).thenAnswer((_) async {});

    // Token + metadata defaults
    when(() => notifications.getToken()).thenAnswer((_) async => tToken);
    when(() => notifications.requestPermission()).thenAnswer((_) async => true);
    when(() => deviceInfo.resolve()).thenAnswer(
      (_) async => const DeviceMetadata(
        deviceType: 0,
        deviceName: 'TestDevice',
        deviceModel: 'TestModel',
        osVersion: 'Android 14',
        appVersion: '1.0.0',
      ),
    );
    when(() => language.currentLanguage).thenReturn('ar');

    // Default cache state — nothing cached yet
    when(() => sharedPrefs.get<String>(any())).thenAnswer((_) async => null);
    when(() => sharedPrefs.get<bool>(StorageKeys.deviceRegistered))
        .thenAnswer((_) async => false);
    when(() => secureStorage.get<String>(StorageKeys.token))
        .thenAnswer((_) async => null);

    // Usecases default to success
    when(() => registerDevice(
          token: any(named: 'token'),
          deviceType: any(named: 'deviceType'),
          language: any(named: 'language'),
          deviceName: any(named: 'deviceName'),
          deviceModel: any(named: 'deviceModel'),
          osVersion: any(named: 'osVersion'),
          appVersion: any(named: 'appVersion'),
        )).thenAnswer((_) async => const Right<Failure, Unit>(unit));
    when(() => linkDevice(token: any(named: 'token')))
        .thenAnswer((_) async => const Right<Failure, Unit>(unit));
    when(() => unlinkDevice(token: any(named: 'token')))
        .thenAnswer((_) async => const Right<Failure, Unit>(unit));

    service = DeviceBootstrapService(
      notifications: notifications,
      deviceInfo: deviceInfo,
      registerDevice: registerDevice,
      linkDevice: linkDevice,
      unlinkDevice: unlinkDevice,
      sharedPrefs: sharedPrefs,
      secureStorage: secureStorage,
      language: language,
    );
  });

  group('bootstrap', () {
    test('anonymous: registers, does not link', () async {
      await service.bootstrap();

      verify(() => registerDevice(
            token: tToken,
            deviceType: 0,
            language: 'ar',
            deviceName: 'TestDevice',
            deviceModel: 'TestModel',
            osVersion: 'Android 14',
            appVersion: '1.0.0',
          )).called(1);
      verifyNever(() => linkDevice(token: any(named: 'token')));
    });

    test('authenticated: registers and links', () async {
      when(() => secureStorage.get<String>(StorageKeys.token))
          .thenAnswer((_) async => tJwt);

      await service.bootstrap();

      verify(() => registerDevice(
            token: any(named: 'token'),
            deviceType: any(named: 'deviceType'),
            language: any(named: 'language'),
            deviceName: any(named: 'deviceName'),
            deviceModel: any(named: 'deviceModel'),
            osVersion: any(named: 'osVersion'),
            appVersion: any(named: 'appVersion'),
          )).called(1);
      verify(() => linkDevice(token: tToken)).called(1);
    });

    test('skips register when cache matches token + lang and registered=true',
        () async {
      when(() => sharedPrefs.get<bool>(StorageKeys.deviceRegistered))
          .thenAnswer((_) async => true);
      when(() => sharedPrefs.get<String>(StorageKeys.lastRegisteredFcm))
          .thenAnswer((_) async => tToken);
      when(() => sharedPrefs.get<String>(StorageKeys.lastRegisteredLang))
          .thenAnswer((_) async => 'ar');

      await service.bootstrap();

      verifyNever(() => registerDevice(
            token: any(named: 'token'),
            deviceType: any(named: 'deviceType'),
            language: any(named: 'language'),
            deviceName: any(named: 'deviceName'),
            deviceModel: any(named: 'deviceModel'),
            osVersion: any(named: 'osVersion'),
            appVersion: any(named: 'appVersion'),
          ));
    });

    test('does not throw when getToken returns null', () async {
      when(() => notifications.getToken()).thenAnswer((_) async => null);

      await service.bootstrap();

      verifyNever(() => registerDevice(
            token: any(named: 'token'),
            deviceType: any(named: 'deviceType'),
            language: any(named: 'language'),
            deviceName: any(named: 'deviceName'),
            deviceModel: any(named: 'deviceModel'),
            osVersion: any(named: 'osVersion'),
            appVersion: any(named: 'appVersion'),
          ));
    });
  });

  group('linkSilently', () {
    test('skips when no JWT in secure storage', () async {
      when(() => sharedPrefs.get<String>(StorageKeys.latestFcmToken))
          .thenAnswer((_) async => tToken);

      await service.linkSilently();

      verifyNever(() => linkDevice(token: any(named: 'token')));
    });

    test('links when JWT present', () async {
      when(() => sharedPrefs.get<String>(StorageKeys.latestFcmToken))
          .thenAnswer((_) async => tToken);
      when(() => secureStorage.get<String>(StorageKeys.token))
          .thenAnswer((_) async => tJwt);

      await service.linkSilently();

      verify(() => linkDevice(token: tToken)).called(1);
    });

    test('on Device-Not-Found failure: re-registers then retries link',
        () async {
      when(() => sharedPrefs.get<String>(StorageKeys.latestFcmToken))
          .thenAnswer((_) async => tToken);
      when(() => secureStorage.get<String>(StorageKeys.token))
          .thenAnswer((_) async => tJwt);

      var firstCall = true;
      when(() => linkDevice(token: any(named: 'token'))).thenAnswer((_) async {
        if (firstCall) {
          firstCall = false;
          return const Left<Failure, Unit>(
            ServerFailure(message: 'Device not found. Register it first.'),
          );
        }
        return const Right<Failure, Unit>(unit);
      });

      await service.linkSilently();

      verify(() => linkDevice(token: tToken)).called(2);
      verify(() => registerDevice(
            token: any(named: 'token'),
            deviceType: any(named: 'deviceType'),
            language: any(named: 'language'),
            deviceName: any(named: 'deviceName'),
            deviceModel: any(named: 'deviceModel'),
            osVersion: any(named: 'osVersion'),
            appVersion: any(named: 'appVersion'),
          )).called(1);
    });
  });

  group('onLanguageChanged', () {
    test('no-op when language unchanged', () async {
      when(() => sharedPrefs.get<String>(StorageKeys.lastRegisteredLang))
          .thenAnswer((_) async => 'ar');

      await service.onLanguageChanged('ar');

      verifyNever(() => registerDevice(
            token: any(named: 'token'),
            deviceType: any(named: 'deviceType'),
            language: any(named: 'language'),
            deviceName: any(named: 'deviceName'),
            deviceModel: any(named: 'deviceModel'),
            osVersion: any(named: 'osVersion'),
            appVersion: any(named: 'appVersion'),
          ));
    });

    test('re-registers with new language when changed', () async {
      when(() => sharedPrefs.get<String>(StorageKeys.lastRegisteredLang))
          .thenAnswer((_) async => 'ar');
      when(() => sharedPrefs.get<String>(StorageKeys.latestFcmToken))
          .thenAnswer((_) async => tToken);

      await service.onLanguageChanged('en');

      verify(() => registerDevice(
            token: tToken,
            deviceType: 0,
            language: 'en',
            deviceName: any(named: 'deviceName'),
            deviceModel: any(named: 'deviceModel'),
            osVersion: any(named: 'osVersion'),
            appVersion: any(named: 'appVersion'),
          )).called(1);
    });
  });

  group('onTokenRefreshed', () {
    test('invalidates caches, re-registers, links if authenticated', () async {
      when(() => secureStorage.get<String>(StorageKeys.token))
          .thenAnswer((_) async => tJwt);

      await service.onTokenRefreshed('fcm-new');

      verify(() => sharedPrefs.remove(StorageKeys.lastRegisteredFcm)).called(1);
      verify(() => sharedPrefs.remove(StorageKeys.lastLinkedFcm)).called(1);
      verify(() => registerDevice(
            token: 'fcm-new',
            deviceType: any(named: 'deviceType'),
            language: any(named: 'language'),
            deviceName: any(named: 'deviceName'),
            deviceModel: any(named: 'deviceModel'),
            osVersion: any(named: 'osVersion'),
            appVersion: any(named: 'appVersion'),
          )).called(1);
      verify(() => linkDevice(token: 'fcm-new')).called(1);
    });
  });
}
