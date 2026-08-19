import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:qeran/features/profile/data/error_codes.dart';
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

  test('parses the image list, ignoring the retired isApproved field', () async {
    // Per-image review is gone, but the server still sends the key — as null
    // now, and historically as a bool. None of those shapes may leak into the
    // entity or fail the parse.
    when(() => api.get(EndPoints.profileImages)).thenAnswer(
      (_) async => {
        'status': 1,
        'data': [
          {'id': 'a', 'url': '/a.jpg', 'isProfile': true, 'isApproved': null},
          {'id': 'b', 'url': '/b.jpg', 'isProfile': false, 'isApproved': false},
          {'id': 'c', 'url': '/c.jpg', 'isProfile': false},
        ],
      },
    );

    final images = await dataSource.getProfileImages();

    expect(images.map((image) => image.id), ['a', 'b', 'c']);
    expect(images.map((image) => image.isProfile), [true, false, false]);
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

    // The upload codes specifically: these arrive through the SAME catch that
    // rephrases 5xx faults, so they have to be translated and rethrown before
    // the generic "couldn't upload" wording can claim them.
    for (final (code, key) in [
      (ProfileImageErrorCodes.limitReached,
          LocaleKeys.profile_photos_max_reached),
      (ProfileImageErrorCodes.tooLarge, LocaleKeys.auth_photo_validation_size),
      (ProfileImageErrorCodes.invalidType,
          LocaleKeys.profile_photos_validation_type),
      (ProfileImageErrorCodes.imageRequired, LocaleKeys.errors_generic),
    ]) {
      test('$code on upload becomes $key, not the upload-failed wording',
          () async {
        stubUploadThrows(
          CodedServerException(message: 'رسالة عربية', errorCode: code),
        );

        await expectLater(
          () => dataSource.addProfileImages([tmpFile]),
          throwsA(
            isA<CodedServerException>()
                .having((e) => e.message, 'message', key)
                .having((e) => e.errorCode, 'errorCode', code),
          ),
        );
      });
    }
  });

  // Classification happens on the code; the backend's Arabic prose never
  // reaches the UI, and the code itself survives so the cubit can act on it.
  group('image error codes translate to locale keys', () {
    test('IMAGE_LAST_ONE on delete', () async {
      when(() => api.delete(EndPoints.profileImage('img-1'))).thenThrow(
        CodedServerException(
          message: 'لا يمكن حذف الصورة الوحيدة',
          errorCode: ProfileImageErrorCodes.lastOne,
        ),
      );

      await expectLater(
        () => dataSource.deleteProfileImage('img-1'),
        throwsA(
          isA<CodedServerException>()
              .having(
                (e) => e.message,
                'message',
                LocaleKeys.profile_photos_last_one,
              )
              .having(
                (e) => e.errorCode,
                'errorCode',
                ProfileImageErrorCodes.lastOne,
              ),
        ),
      );
    });

    test('IMAGE_NOT_FOUND on set-main', () async {
      when(() => api.put(EndPoints.setMainProfileImage('img-9'))).thenThrow(
        CodedServerException(
          message: 'الصورة غير موجودة',
          errorCode: ProfileImageErrorCodes.notFound,
        ),
      );

      await expectLater(
        () => dataSource.setMainProfileImage('img-9'),
        throwsA(
          isA<CodedServerException>().having(
            (e) => e.message,
            'message',
            LocaleKeys.profile_photos_not_found,
          ),
        ),
      );
    });

    // The list endpoint is not documented to return these, but it goes
    // through the same wrapper so a code appearing there is still translated.
    test('the list endpoint is wrapped too', () async {
      when(() => api.get(EndPoints.profileImages)).thenThrow(
        CodedServerException(
          message: 'الصورة غير موجودة',
          errorCode: ProfileImageErrorCodes.notFound,
        ),
      );

      await expectLater(
        () => dataSource.getProfileImages(),
        throwsA(
          isA<CodedServerException>().having(
            (e) => e.message,
            'message',
            LocaleKeys.profile_photos_not_found,
          ),
        ),
      );
    });

    test('an unknown code is rethrown untouched', () async {
      when(() => api.delete(EndPoints.profileImage('img-1'))).thenThrow(
        CodedServerException(
          message: 'شيء آخر تماماً',
          errorCode: 'SOMETHING_ELSE',
        ),
      );

      await expectLater(
        () => dataSource.deleteProfileImage('img-1'),
        throwsA(
          isA<CodedServerException>().having(
            (e) => e.message,
            'message',
            'شيء آخر تماماً',
          ),
        ),
      );
    });
  });
}
