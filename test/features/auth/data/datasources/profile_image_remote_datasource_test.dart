import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/features/auth/data/datasources/profile_image_remote_datasource.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class MockApiConsumer extends Mock implements ApiConsumer {}

class MockStorage extends Mock implements StorageService {}

class _FakeFile extends Fake implements File {}

void main() {
  setUpAll(() {
    registerFallbackValue(<File>[]);
  });

  late MockApiConsumer api;
  late MockStorage storage;
  late ProfileImageRemoteDataSourceImpl ds;
  late Directory tmpDir;
  late File tmpFile;

  setUp(() async {
    api = MockApiConsumer();
    storage = MockStorage();

    when(() => storage.get<String>(StorageKeys.token))
        .thenAnswer((_) async => 'jwt');

    ds = ProfileImageRemoteDataSourceImpl(
      apiConsumer: api,
      secureStorage: storage,
    );

    tmpDir = await Directory.systemTemp.createTemp('ds_test_');
    tmpFile = File('${tmpDir.path}/a.jpg');
    await tmpFile.writeAsBytes([1, 2, 3]);
  });

  tearDown(() async {
    if (tmpDir.existsSync()) {
      await tmpDir.delete(recursive: true);
    }
  });

  group('uploadImages', () {
    test('forwards files to apiConsumer.postMultipart with fieldName=images',
        () async {
      when(() => api.postMultipart(
            any(),
            files: any(named: 'files'),
            fieldName: any(named: 'fieldName'),
            fields: any(named: 'fields'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => {
            'status': 1,
            'message': 'OK',
            'data': null,
          });

      final result = await ds.uploadImages(images: [tmpFile]);

      verify(() => api.postMultipart(
            EndPoints.profileImages,
            files: [tmpFile],
            fieldName: 'images',
          )).called(1);
      expect(result.message, 'OK');
      expect(result.status, 1);
    });

    test('throws AuthException when token is null', () {
      when(() => storage.get<String>(StorageKeys.token))
          .thenAnswer((_) async => null);

      expect(
        () => ds.uploadImages(images: [_FakeFile()]),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            equals(LocaleKeys.errors_unauthorized_access),
          ),
        ),
      );
    });

    test('throws AuthException when token is empty', () {
      when(() => storage.get<String>(StorageKeys.token))
          .thenAnswer((_) async => '');

      expect(
        () => ds.uploadImages(images: [_FakeFile()]),
        throwsA(isA<AuthException>()),
      );
    });

    test('re-maps transport-error keys to errors_upload_failed', () async {
      when(() => api.postMultipart(
            any(),
            files: any(named: 'files'),
            fieldName: any(named: 'fieldName'),
            fields: any(named: 'fields'),
            timeout: any(named: 'timeout'),
          )).thenThrow(
        ServerException(message: LocaleKeys.errors_unauthorized),
      );

      expect(
        () => ds.uploadImages(images: [tmpFile]),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            equals(LocaleKeys.errors_upload_failed),
          ),
        ),
      );
    });

    test('re-maps errors_timeout to errors_upload_failed', () async {
      when(() => api.postMultipart(
            any(),
            files: any(named: 'files'),
            fieldName: any(named: 'fieldName'),
            fields: any(named: 'fields'),
            timeout: any(named: 'timeout'),
          )).thenThrow(
        ServerException(message: LocaleKeys.errors_timeout),
      );

      expect(
        () => ds.uploadImages(images: [tmpFile]),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            equals(LocaleKeys.errors_upload_failed),
          ),
        ),
      );
    });

    test('passes server-supplied error messages through unchanged', () async {
      when(() => api.postMultipart(
            any(),
            files: any(named: 'files'),
            fieldName: any(named: 'fieldName'),
            fields: any(named: 'fields'),
            timeout: any(named: 'timeout'),
          )).thenThrow(
        ServerException(message: 'الصورة كبيرة جداً'),
      );

      expect(
        () => ds.uploadImages(images: [tmpFile]),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            equals('الصورة كبيرة جداً'),
          ),
        ),
      );
    });
  });
}
