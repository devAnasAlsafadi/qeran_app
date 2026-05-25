import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/domain/entities/success_response.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/devices/data/datasources/device_remote_datasource.dart';
import 'package:qeran/features/devices/data/models/link_device_request_model.dart';
import 'package:qeran/features/devices/data/models/register_device_request_model.dart';
import 'package:qeran/features/devices/data/repositories/device_repository_impl.dart';

class MockDataSource extends Mock implements DeviceRemoteDataSource {}

class _AnyRegister extends Fake implements RegisterDeviceRequestModel {}

class _AnyLink extends Fake implements LinkDeviceRequestModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(_AnyRegister());
    registerFallbackValue(_AnyLink());
  });

  late MockDataSource dataSource;
  late DeviceRepositoryImpl repository;

  setUp(() {
    dataSource = MockDataSource();
    repository = DeviceRepositoryImpl(dataSource);
  });

  group('registerDevice', () {
    test('returns Right(unit) on success', () async {
      when(() => dataSource.registerDevice(any())).thenAnswer(
        (_) async => SuccessResponse<void>(status: 1, message: 'OK'),
      );

      final result = await repository.registerDevice(
        token: 'fcm-1',
        deviceType: 0,
        language: 'ar',
      );

      expect(result, equals(const Right<Failure, Unit>(unit)));
    });

    test('returns Left(ServerFailure) when DataSource throws ServerException',
        () async {
      when(() => dataSource.registerDevice(any()))
          .thenThrow(ServerException(message: 'boom'));

      final result = await repository.registerDevice(
        token: 'fcm-1',
        deviceType: 0,
        language: 'ar',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'boom');
        },
        (_) => fail('expected Left(ServerFailure)'),
      );
    });
  });

  group('linkDevice', () {
    test('returns Right(unit) on success', () async {
      when(() => dataSource.linkDevice(any())).thenAnswer(
        (_) async => SuccessResponse<void>(status: 1, message: 'OK'),
      );

      final result = await repository.linkDevice(token: 'fcm-1');

      expect(result, equals(const Right<Failure, Unit>(unit)));
    });

    test('propagates server message into Failure', () async {
      when(() => dataSource.linkDevice(any())).thenThrow(
        ServerException(message: 'Device not found. Register it first.'),
      );

      final result = await repository.linkDevice(token: 'fcm-1');

      result.fold(
        (failure) =>
            expect(failure.message, 'Device not found. Register it first.'),
        (_) => fail('expected Left'),
      );
    });
  });
}
