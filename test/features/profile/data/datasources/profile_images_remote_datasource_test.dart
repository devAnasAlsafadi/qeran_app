import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class _MockApiConsumer extends Mock implements ApiConsumer {}

class _MockStorage extends Mock implements StorageService {}

class _FakeFile extends Fake implements File {}

void main() {
  late _MockApiConsumer api;
  late _MockStorage storage;
  late ProfileRemoteDataSourceImpl dataSource;

  setUp(() {
    api = _MockApiConsumer();
    storage = _MockStorage();
    when(
      () => storage.get<String>(StorageKeys.token),
    ).thenAnswer((_) async => 'token');
    dataSource = ProfileRemoteDataSourceImpl(
      apiConsumer: api,
      secureStorage: storage,
    );
  });

  test('reads isApproved for every profile image', () async {
    when(() => api.get(EndPoints.profileImages)).thenAnswer(
      (_) async => {
        'status': 1,
        'data': [
          {
            'id': 'approved',
            'url': '/a.jpg',
            'isProfile': true,
            'isApproved': true,
          },
          {
            'id': 'pending',
            'url': '/b.jpg',
            'isProfile': false,
            'isApproved': false,
          },
        ],
      },
    );

    final images = await dataSource.getProfileImages();

    expect(images.map((image) => image.isApproved), [true, false]);
  });

  test('uses the documented add, delete, and set-main endpoints', () async {
    final files = [File('new-photo.jpg')];
    when(
      () => api.postMultipart(
        EndPoints.profileImages,
        files: files,
        fieldName: 'images',
      ),
    ).thenAnswer((_) async => <String, dynamic>{});
    when(
      () => api.delete(EndPoints.profileImage('image-1')),
    ).thenAnswer((_) async => <String, dynamic>{});
    when(
      () => api.put(EndPoints.setMainProfileImage('image-1')),
    ).thenAnswer((_) async => <String, dynamic>{});

    await dataSource.addProfileImages(files);
    await dataSource.deleteProfileImage('image-1');
    await dataSource.setMainProfileImage('image-1');

    verify(
      () => api.postMultipart(
        EndPoints.profileImages,
        files: files,
        fieldName: 'images',
      ),
    ).called(1);
    verify(() => api.delete(EndPoints.profileImage('image-1'))).called(1);
    verify(() => api.put(EndPoints.setMainProfileImage('image-1'))).called(1);
  });

  group('addProfileImages — migrated from the retired auth upload stack', () {
    late Directory tmpDir;
    late File tmpFile;

    setUp(() async {
      registerFallbackValue(<File>[]);
      tmpDir = await Directory.systemTemp.createTemp('profile_ds_');
      tmpFile = File('${tmpDir.path}${Platform.pathSeparator}a.jpg');
      await tmpFile.writeAsBytes([1, 2, 3]);
    });

    tearDown(() async {
      if (tmpDir.existsSync()) await tmpDir.delete(recursive: true);
    });

    void stubUpload(Object? Function() answer) {
      when(
        () => api.postMultipart(
          any(),
          files: any(named: 'files'),
          fieldName: any(named: 'fieldName'),
          fields: any(named: 'fields'),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer((_) async => answer());
    }

    void stubUploadThrows(Object error) {
      when(
        () => api.postMultipart(
          any(),
          files: any(named: 'files'),
          fieldName: any(named: 'fieldName'),
          fields: any(named: 'fields'),
          timeout: any(named: 'timeout'),
        ),
      ).thenThrow(error);
    }

    test('forwards the batch with fieldName=images', () async {
      stubUpload(() => {'status': 1, 'message': 'OK', 'data': null});

      await dataSource.addProfileImages([tmpFile]);

      verify(
        () => api.postMultipart(
          EndPoints.profileImages,
          files: [tmpFile],
          fieldName: 'images',
        ),
      ).called(1);
    });

    test('a missing token throws before the request is sent', () async {
      when(
        () => storage.get<String>(StorageKeys.token),
      ).thenAnswer((_) async => null);

      await expectLater(
        () => dataSource.addProfileImages([_FakeFile()]),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            LocaleKeys.errors_unauthorized_access,
          ),
        ),
      );
      verifyNever(
        () => api.postMultipart(
          any(),
          files: any(named: 'files'),
          fieldName: any(named: 'fieldName'),
        ),
      );
    });

    test('an empty token throws before the request is sent', () async {
      when(
        () => storage.get<String>(StorageKeys.token),
      ).thenAnswer((_) async => '');

      await expectLater(
        () => dataSource.addProfileImages([_FakeFile()]),
        throwsA(isA<AuthException>()),
      );
    });

    test('a 5xx becomes the upload-specific message', () async {
      stubUploadThrows(
        ServerException(message: LocaleKeys.errors_server, statusCode: 500),
      );

      await expectLater(
        () => dataSource.addProfileImages([tmpFile]),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            LocaleKeys.errors_upload_failed,
          ),
        ),
      );
    });

    test('a timeout keeps its own key rather than being coarsened', () async {
      stubUploadThrows(ServerException(message: LocaleKeys.errors_timeout));

      await expectLater(
        () => dataSource.addProfileImages([tmpFile]),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            LocaleKeys.errors_timeout,
          ),
        ),
      );
    });

    test('a server-supplied message passes through unchanged', () async {
      stubUploadThrows(ServerException(message: 'الصورة كبيرة جداً'));

      await expectLater(
        () => dataSource.addProfileImages([tmpFile]),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'الصورة كبيرة جداً',
          ),
        ),
      );
    });
  });
}
