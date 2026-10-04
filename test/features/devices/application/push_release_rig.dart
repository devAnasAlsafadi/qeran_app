import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/services/device_info_service.dart';
import 'package:qeran/core/services/language_service.dart';
import 'package:qeran/core/services/notification_service.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/features/devices/application/device_bootstrap_service.dart';
import 'package:qeran/features/devices/domain/usecases/link_device_usecase.dart';
import 'package:qeran/features/devices/domain/usecases/register_device_usecase.dart';
import 'package:qeran/features/devices/domain/usecases/unlink_device_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockNotifications extends Mock implements NotificationService {}

class _MockDeviceInfo extends Mock implements DeviceInfoService {}

class _MockRegister extends Mock implements RegisterDeviceUseCase {}

class _MockLink extends Mock implements LinkDeviceUseCase {}

class MockUnlink extends Mock implements UnlinkDeviceUseCase {}

class _MockSecure extends Mock implements StorageService {}

class _MockLanguage extends Mock implements LanguageService {}

const oldToken = 'fcm-old';
const newToken = 'fcm-new';

/// A phone signed in, its token [oldToken] registered and linked.
const signedInPhone = <String, Object>{
  StorageKeys.latestFcmToken: oldToken,
  StorageKeys.lastRegisteredFcm: oldToken,
  StorageKeys.lastRegisteredLang: 'ar',
  StorageKeys.deviceRegistered: true,
};

/// [DeviceBootstrapService] over in-memory prefs. What it asks of the server
/// and of FCM is written to [calls], in order; FCM hands out [newToken].
class PushRig {
  final calls = <String>[];
  final notifications = MockNotifications();
  final unlink = MockUnlink();
  final _register = _MockRegister();
  final _link = _MockLink();
  final _secure = _MockSecure();
  late SharedPrefService prefs;
  late DeviceBootstrapService service;

  PushRig() {
    when(
      notifications.deleteToken,
    ).thenAnswer((_) async => calls.add('delete'));
    when(notifications.getToken).thenAnswer((_) async => newToken);
    when(
      () => _secure.get<String>(StorageKeys.token),
    ).thenAnswer((_) async => 'jwt');
    _logged(() => unlink(token: any(named: 'token')), 'unlink');
    _logged(() => _link(token: any(named: 'token')), 'link');
    _logged(
      () => _register(
        token: any(named: 'token'),
        deviceType: any(named: 'deviceType'),
        language: any(named: 'language'),
        deviceName: any(named: 'deviceName'),
        deviceModel: any(named: 'deviceModel'),
        osVersion: any(named: 'osVersion'),
        appVersion: any(named: 'appVersion'),
      ),
      'register',
    );
  }

  void _logged<F>(Future<Either<F, Unit>> Function() call, String name) =>
      when(call).thenAnswer((i) async {
        calls.add('$name ${i.namedArguments[#token]}');
        return Right<F, Unit>(unit);
      });

  Future<void> start([Map<String, Object> stored = signedInPhone]) async {
    SharedPreferences.setMockInitialValues(stored);
    prefs = SharedPrefService(await SharedPreferences.getInstance());
    final deviceInfo = _MockDeviceInfo();
    when(deviceInfo.resolve).thenAnswer(
      (_) async => const DeviceMetadata(
        deviceType: 0,
        deviceName: 'Phone',
        deviceModel: 'Model',
        osVersion: 'Android 14',
        appVersion: '1.0.0',
      ),
    );
    final language = _MockLanguage();
    when(() => language.currentLanguage).thenReturn('ar');
    service = DeviceBootstrapService(
      notifications: notifications,
      deviceInfo: deviceInfo,
      registerDevice: _register,
      linkDevice: _link,
      unlinkDevice: unlink,
      sharedPrefs: prefs,
      secureStorage: _secure,
      language: language,
    );
  }
}
