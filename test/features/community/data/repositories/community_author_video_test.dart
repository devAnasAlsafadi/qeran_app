import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/community/data/datasources/community_author_remote_datasource.dart';
import 'package:qeran/features/community/data/models/video_upload_grant_model.dart';
import 'package:qeran/features/community/data/repositories/community_author_repository_impl.dart';
import 'package:qeran/features/community/data/repositories/community_post_changes.dart';
import 'package:qeran/features/community/domain/entities/media_refusal.dart';
import 'package:qeran/features/community/domain/entities/media_upload_outcome.dart';
import 'package:qeran/features/community/domain/entities/picked_video.dart';
import 'package:qeran/features/community/domain/entities/video_upload_grant.dart';

import '../../domain/fake_video_compressor.dart';

class _MockDataSource extends Mock implements CommunityAuthorRemoteDataSource {}

final _file = PickedVideo(
  path: 'v.mov.mp4',
  container: VideoContainer.mp4,
  info: clip(width: 720, height: 1280, bytes: 4096),
);

final _grant = VideoUploadGrant(
  mediaId: 'v-1',
  endpoint: Uri.parse('https://video.bunnycdn.com/tusupload'),
  headers: const {'VideoId': 'vid-1'},
  metadata: const {'title': 'v-1'},
);

/// Her video through the repository (6.8, tus, 6.2).
void main() {
  late _MockDataSource ds;
  late CommunityAuthorRepositoryImpl repo;
  setUpAll(() => registerFallbackValue(Uri()));
  setUp(() {
    ds = _MockDataSource();
    repo = CommunityAuthorRepositoryImpl(ds, changes: CommunityPostChanges());
  });

  void grantAnswers(Future<VideoUploadGrantModel> Function() answer) => when(
    () => ds.requestVideoUpload(
      sizeBytes: any(named: 'sizeBytes'),
      durationSeconds: any(named: 'durationSeconds'),
      contentType: any(named: 'contentType'),
      width: any(named: 'width'),
      height: any(named: 'height'),
    ),
  ).thenAnswer((_) => answer());

  Future<Object?> grant() async => (await repo.requestVideoUpload(
    _file,
    durationSeconds: 30,
  )).fold((f) => f, (o) => o);

  test('6.8 asks for the file that goes up, at the length she was checked '
      'at; the grant comes back', () async {
    grantAnswers(
      () async => VideoUploadGrantModel(
        mediaId: 'v-1',
        endpoint: _grant.endpoint,
        headers: _grant.headers,
        metadata: _grant.metadata,
        expiresAt: null,
      ),
    );

    expect(
      await grant(),
      isA<MediaUploaded<VideoUploadGrant>>().having(
        (o) => o.value,
        'value',
        _grant,
      ),
    );
    verify(
      () => ds.requestVideoUpload(
        sizeBytes: 4096,
        durationSeconds: 30,
        contentType: 'video/mp4',
        width: 720,
        height: 1280,
      ),
    ).called(1);
  });

  test('the server\'s own checks and the video service as outcomes; the '
      'limit on media stays a failure (S7)', () async {
    Future<Object?> on(String code) {
      grantAnswers(
        () async => throw CodedServerException(message: 'x', errorCode: code),
      );
      return grant();
    }

    expect(
      await on('MEDIA_TOO_LONG'),
      isA<MediaUploadRefused<VideoUploadGrant>>().having(
        (o) => o.refusal,
        'refusal',
        MediaRefusal.tooLong,
      ),
    );
    expect(
      await on('VIDEO_SERVICE_UNAVAILABLE'),
      isA<MediaVideoUnavailable<VideoUploadGrant>>(),
    );
    expect(await on('MEDIA_LIMIT_REACHED'), isA<CodedServerFailure>());
  });

  test('the file to tus: its path and length, the grant\'s endpoint, '
      'headers and metadata; her cancel and offline as failures', () async {
    void tus(Future<void> Function() answer) => when(
      () => ds.uploadVideo(
        path: any(named: 'path'),
        length: any(named: 'length'),
        endpoint: any(named: 'endpoint'),
        headers: any(named: 'headers'),
        metadata: any(named: 'metadata'),
        resumeAt: any(named: 'resumeAt'),
        onCreated: any(named: 'onCreated'),
        onProgress: any(named: 'onProgress'),
        cancel: any(named: 'cancel'),
      ),
    ).thenAnswer((_) => answer());

    tus(() async {});
    expect(
      await repo.uploadVideo(_grant, _file),
      const Right<Failure, Unit>(unit),
    );
    verify(
      () => ds.uploadVideo(
        path: 'v.mov.mp4',
        length: 4096,
        endpoint: _grant.endpoint,
        headers: _grant.headers,
        metadata: _grant.metadata,
      ),
    ).called(1);

    tus(() async => throw const UploadCancelledException());
    expect(
      await repo.uploadVideo(_grant, _file),
      const Left<Failure, Unit>(UploadCancelledFailure()),
    );
    tus(() async => throw const OfflineException());
    expect(
      await repo.uploadVideo(_grant, _file),
      const Left<Failure, Unit>(OfflineFailure()),
    );
  });
}
