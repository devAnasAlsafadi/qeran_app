import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/community/data/datasources/community_author_remote_datasource.dart';
import 'package:qeran/features/community/data/repositories/community_author_repository_impl.dart';
import 'package:qeran/features/community/data/repositories/community_post_changes.dart';
import 'package:qeran/features/community/domain/entities/media_refusal.dart';
import 'package:qeran/features/community/domain/entities/media_upload_outcome.dart';

class _MockDataSource extends Mock implements CommunityAuthorRemoteDataSource {}

const _file = UploadFile(
  path: '/tmp/a.jpg',
  fileName: 'image.jpg',
  contentType: 'image/jpeg',
);

/// Her media through the repository (6.7, 6.9).
void main() {
  late _MockDataSource ds;
  late CommunityAuthorRepositoryImpl repo;

  setUpAll(() => registerFallbackValue(_file));
  setUp(() {
    ds = _MockDataSource();
    repo = CommunityAuthorRepositoryImpl(ds, changes: CommunityPostChanges());
  });

  void upload(Future<String> Function() answer) => when(
    () => ds.uploadImage(
      any(),
      onProgress: any(named: 'onProgress'),
      cancel: any(named: 'cancel'),
    ),
  ).thenAnswer((_) => answer());

  Object? uploaded(Either<Failure, MediaUploadOutcome<String>> r) =>
      r.fold((f) => f, (o) => o);

  test('uploaded: its mediaId, progress and cancel passed through', () async {
    upload(() async => 'm-1');
    final cancel = UploadCancel();
    void progress(int sent, int total) {}

    final outcome = uploaded(
      await repo.uploadImage(_file, onProgress: progress, cancel: cancel),
    );

    expect((outcome as MediaUploaded<String>).value, 'm-1');
    verify(
      () => ds.uploadImage(_file, onProgress: progress, cancel: cancel),
    ).called(1);
  });

  test('the server refuses it: an outcome (Q3)', () async {
    upload(
      () async => throw CodedServerException(
        message: 'x',
        errorCode: 'MEDIA_TOO_LARGE',
      ),
    );

    expect(
      uploaded(await repo.uploadImage(_file)),
      isA<MediaUploadRefused<String>>().having(
        (o) => o.refusal,
        'refusal',
        MediaRefusal.tooLarge,
      ),
    );
  });

  test('her cancel: UploadCancelledFailure; offline: OfflineFailure', () async {
    upload(() async => throw const UploadCancelledException());
    expect(
      uploaded(await repo.uploadImage(_file)),
      const UploadCancelledFailure(),
    );

    upload(() async => throw const OfflineException());
    expect(uploaded(await repo.uploadImage(_file)), const OfflineFailure());
  });

  test('deleting media: done, or the failure', () async {
    when(() => ds.deleteMedia('m-1')).thenAnswer((_) async {});
    expect(await repo.deleteMedia('m-1'), const Right<Failure, Unit>(unit));

    when(() => ds.deleteMedia('m-2')).thenThrow(const OfflineException());
    expect(
      await repo.deleteMedia('m-2'),
      const Left<Failure, Unit>(OfflineFailure()),
    );
  });
}
