import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/features/devices/data/datasources/device_remote_datasource.dart';
import 'package:qeran/features/devices/data/models/link_device_request_model.dart';
import 'package:qeran/features/devices/data/models/register_device_request_model.dart';

class MockApiConsumer extends Mock implements ApiConsumer {}

void main() {
  late MockApiConsumer apiConsumer;
  late DeviceRemoteDataSourceImpl dataSource;

  setUp(() {
    apiConsumer = MockApiConsumer();
    dataSource = DeviceRemoteDataSourceImpl(apiConsumer: apiConsumer);
  });

  Map<String, dynamic> okResponse() => {
    'status': 1,
    'data': null,
    'message': 'OK',
  };

  group('registerDevice', () {
    test('POSTs Devices/register with the exact body shape from the new doc',
        () async {
      when(
        () => apiConsumer.post(any(), body: any(named: 'body')),
      ).thenAnswer((_) async => okResponse());

      final request = RegisterDeviceRequestModel(
        token: 'fcm-abc',
        deviceType: 0,
        language: 'ar',
        deviceName: 'Pixel 7',
        deviceModel: 'GP4BC',
        osVersion: 'Android 14',
        appVersion: '1.0.0',
      );

      await dataSource.registerDevice(request);

      final captured = verify(
        () => apiConsumer.post(
          captureAny(),
          body: captureAny(named: 'body'),
        ),
      ).captured;
      expect(captured.first, 'Devices/register');
      expect(captured.last, {
        'token': 'fcm-abc',
        'deviceType': 0,
        'deviceName': 'Pixel 7',
        'deviceModel': 'GP4BC',
        'osVersion': 'Android 14',
        'appVersion': '1.0.0',
        'language': 'ar',
      });
    });

    test('omits optional fields when null', () async {
      when(
        () => apiConsumer.post(any(), body: any(named: 'body')),
      ).thenAnswer((_) async => okResponse());

      const request = RegisterDeviceRequestModel(
        token: 'fcm-xyz',
        deviceType: 1,
        language: 'en',
      );

      await dataSource.registerDevice(request);

      final body = verify(
        () => apiConsumer.post(any(), body: captureAny(named: 'body')),
      ).captured.single as Map<String, dynamic>;
      expect(body, {'token': 'fcm-xyz', 'deviceType': 1, 'language': 'en'});
      expect(body.containsKey('deviceName'), isFalse);
      expect(body.containsKey('osVersion'), isFalse);
    });
  });

  group('linkDevice', () {
    test('POSTs Devices/link with body { token } only', () async {
      when(
        () => apiConsumer.post(any(), body: any(named: 'body')),
      ).thenAnswer((_) async => okResponse());

      const request = LinkDeviceRequestModel(token: 'fcm-abc');

      await dataSource.linkDevice(request);

      final captured = verify(
        () => apiConsumer.post(
          captureAny(),
          body: captureAny(named: 'body'),
        ),
      ).captured;
      expect(captured.first, 'Devices/link');
      expect(captured.last, {'token': 'fcm-abc'});
    });
  });
}
