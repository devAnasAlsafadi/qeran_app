import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/progress_uploader.dart';
import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/community/data/datasources/community_author_refusing_datasource.dart';
import 'package:qeran/features/community/data/datasources/community_author_remote_datasource_impl.dart';

import '../../fixtures/community_fixtures.dart';

class _MockApiConsumer extends Mock implements ApiConsumer {}

class _MockUploader extends Mock implements ProgressUploader {}

const _file = UploadFile(
  path: '/tmp/scaled_IMG.heic',
  fileName: 'image.jpg',
  contentType: 'image/jpeg',
);

/// Her media (contract §6.7, §6.9).
void main() {
  late _MockApiConsumer api;
  late _MockUploader uploader;
  late CommunityAuthorRemoteDataSourceImpl ds;

  setUpAll(() => registerFallbackValue(_file));
  setUp(() {
    api = _MockApiConsumer();
    uploader = _MockUploader();
    ds = CommunityAuthorRemoteDataSourceImpl(
      apiConsumer: api,
      uploader: uploader,
    );
  });

  void uploadAnswers(Object? data) => when(
    () => uploader.postFile(
      any(),
      fieldName: any(named: 'fieldName'),
      file: any(named: 'file'),
      onProgress: any(named: 'onProgress'),
      cancel: any(named: 'cancel'),
    ),
  ).thenAnswer((_) async => {'status': 1, 'data': data});

  test('an image: POST community/media/images, field «image», one file '
      'with its progress and cancel; the mediaId comes back', () async {
    uploadAnswers({
      'mediaId': 'm-1',
      'url': '/api/community/media/m-1',
      'width': 1600,
      'height': 1200,
    });
    final cancel = UploadCancel();
    void progress(int sent, int total) {}

    final id = await ds.uploadImage(
      _file,
      onProgress: progress,
      cancel: cancel,
    );

    expect(id, 'm-1');
    verify(
      () => uploader.postFile(
        'community/media/images',
        fieldName: 'image',
        file: _file,
        onProgress: progress,
        cancel: cancel,
      ),
    ).called(1);
  });

  test('an answer without the mediaId is a server fault', () async {
    uploadAnswers({'url': '/x'});

    expect(ds.uploadImage(_file), throwsA(isA<ServerException>()));
  });

  test('deleting media: DELETE community/media/{id}', () async {
    when(() => api.delete(any())).thenAnswer((_) async => {'status': 1});

    await ds.deleteMedia('m-1');

    verify(() => api.delete('community/media/m-1')).called(1);
  });

  test('the dev-flag build refuses uploads too, before anything is sent', () {
    const refusing = CommunityAuthorRefusingDataSource();

    expect(refusing.uploadImage(_file), throwsA(isA<ServerException>()));
    expect(refusing.deleteMedia('m-1'), throwsA(isA<ServerException>()));
  });

  test('6.2 with images: imageMediaIds in her order', () async {
    when(
      () => api.post(any(), body: any(named: 'body')),
    ).thenAnswer((_) async => {'status': 1, 'data': post(id: 31)});

    await ds.createPost(
      text: 'إرشاد',
      clientRequestId: 'req-1',
      imageMediaIds: ['m-2', 'm-1'],
    );

    verify(
      () => api.post(
        'community/posts',
        body: {
          'text': 'إرشاد',
          'imageMediaIds': ['m-2', 'm-1'],
          'clientRequestId': 'req-1',
        },
      ),
    ).called(1);
  });
}
