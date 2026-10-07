import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/progress_uploader.dart';
import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/community/data/datasources/community_author_refusing_datasource.dart';
import 'package:qeran/features/community/data/datasources/community_author_remote_datasource_impl.dart';
import 'package:qeran/features/community/domain/ports/resumable_uploader.dart';

import '../../fixtures/community_fixtures.dart';

class _MockApiConsumer extends Mock implements ApiConsumer {}

class _MockVideoUploader extends Mock implements ResumableUploader {}

/// 6.8's answer as Bunny's grant comes (contract §6.8).
Map<String, dynamic> grantJson({
  Object? mediaId = 'v-1',
  Object? endpoint = 'https://video.bunnycdn.com/tusupload',
  Object? protocol = 'tus',
}) => {
  'mediaId': mediaId,
  'upload': {
    'protocol': protocol,
    'endpoint': endpoint,
    'headers': {
      'AuthorizationSignature': 'sig',
      'AuthorizationExpire': 1760000000,
      'VideoId': 'vid-1',
      'LibraryId': 'lib-1',
    },
    'metadata': {'filetype': 'video/mp4', 'title': 'v-1'},
    'expiresAt': '2026-10-08T09:00:00Z',
  },
};

/// Her video (contract §6.8, §6.2).
void main() {
  late _MockApiConsumer api;
  late _MockVideoUploader tus;
  late CommunityAuthorRemoteDataSourceImpl ds;

  setUpAll(() => registerFallbackValue(Uri()));
  setUp(() {
    api = _MockApiConsumer();
    tus = _MockVideoUploader();
    ds = CommunityAuthorRemoteDataSourceImpl(
      apiConsumer: api,
      uploader: _MockProgressUploader(),
      videoUploader: tus,
    );
  });

  void grantAnswers(Map<String, dynamic> data) => when(
    () => api.post(any(), body: any(named: 'body')),
  ).thenAnswer((_) async => {'status': 1, 'data': data});

  Future<void> askGrant() => ds.requestVideoUpload(
    sizeBytes: 4194304,
    durationSeconds: 30,
    contentType: 'video/mp4',
    width: 720,
    height: 1280,
  );

  test('6.8: POST community/media/videos with the file\'s size, length, '
      'type and display size; the grant, every header as text', () async {
    grantAnswers(grantJson());

    final grant = await ds.requestVideoUpload(
      sizeBytes: 4194304,
      durationSeconds: 30,
      contentType: 'video/mp4',
      width: 720,
      height: 1280,
    );

    verify(
      () => api.post(
        'community/media/videos',
        body: {
          'sizeBytes': 4194304,
          'durationSeconds': 30,
          'contentType': 'video/mp4',
          'width': 720,
          'height': 1280,
        },
      ),
    ).called(1);
    final entity = grant.toEntity();
    expect(entity.mediaId, 'v-1');
    expect(entity.endpoint, Uri.parse('https://video.bunnycdn.com/tusupload'));
    expect(entity.headers['AuthorizationExpire'], '1760000000');
    expect(entity.headers['VideoId'], 'vid-1');
    expect(entity.metadata, {'filetype': 'video/mp4', 'title': 'v-1'});
    expect(
      entity.expiresAt?.isAtSameMomentAs(DateTime.utc(2026, 10, 8, 9)),
      isTrue,
    );
  });

  test('a grant with no id, a plain-http endpoint or another protocol is a '
      'server fault: nothing goes up under it', () async {
    for (final bad in [
      grantJson(mediaId: null),
      grantJson(endpoint: 'http://video.bunnycdn.com/tusupload'),
      grantJson(protocol: 's3'),
    ]) {
      grantAnswers(bad);
      await expectLater(askGrant(), throwsA(isA<ServerException>()));
    }
  });

  test('the file goes to the tus client with the grant as given', () async {
    when(
      () => tus.upload(
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
    ).thenAnswer((_) async {});
    final endpoint = Uri.parse('https://video.bunnycdn.com/tusupload');
    final at = Uri.parse('https://video.bunnycdn.com/tusupload/vid-1');
    final cancel = UploadCancel();
    void created(Uri url) {}
    void progress(int sent, int total) {}

    await ds.uploadVideo(
      path: 'v.mp4',
      length: 10,
      endpoint: endpoint,
      headers: const {'VideoId': 'vid-1'},
      metadata: const {'title': 'v-1'},
      resumeAt: at,
      onCreated: created,
      onProgress: progress,
      cancel: cancel,
    );

    verify(
      () => tus.upload(
        path: 'v.mp4',
        length: 10,
        endpoint: endpoint,
        headers: const {'VideoId': 'vid-1'},
        metadata: const {'title': 'v-1'},
        resumeAt: at,
        onCreated: created,
        onProgress: progress,
        cancel: cancel,
      ),
    ).called(1);
  });

  test('6.2 with her video: videoMediaId, no images', () async {
    when(
      () => api.post(any(), body: any(named: 'body')),
    ).thenAnswer((_) async => {'status': 1, 'data': post(id: 31)});

    await ds.createPost(
      text: 'إرشاد',
      clientRequestId: 'req-1',
      videoMediaId: 'v-1',
    );

    verify(
      () => api.post(
        'community/posts',
        body: {
          'text': 'إرشاد',
          'videoMediaId': 'v-1',
          'clientRequestId': 'req-1',
        },
      ),
    ).called(1);
  });

  test('the dev-flag build refuses the grant too', () {
    const refusing = CommunityAuthorRefusingDataSource();

    expect(
      refusing.requestVideoUpload(
        sizeBytes: 1,
        durationSeconds: 1,
        contentType: 'video/mp4',
        width: 1,
        height: 1,
      ),
      throwsA(isA<ServerException>()),
    );
  });
}

class _MockProgressUploader extends Mock implements ProgressUploader {}
