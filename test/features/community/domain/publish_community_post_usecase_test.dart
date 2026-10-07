import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/media_refusal.dart';
import 'package:qeran/features/community/domain/entities/media_upload_outcome.dart';
import 'package:qeran/features/community/domain/entities/picked_video.dart';
import 'package:qeran/features/community/domain/entities/post_draft.dart';
import 'package:qeran/features/community/domain/entities/post_publish_outcome.dart';
import 'package:qeran/features/community/domain/usecases/publish_community_post_usecase.dart';

import '../fixtures/community_post_fixtures.dart';
import 'fake_video_compressor.dart';
import 'publish_rig.dart';

void main() {
  late PublishRig rig;
  late PublishCommunityPostUseCase publish;
  setUp(() {
    rig = PublishRig();
    publish = PublishCommunityPostUseCase(rig.repository, rig.compressor);
  });

  final a = pickedImage('a.jpg');
  final b = pickedImage('b.jpg', size: 300);
  final draft = PostDraft(text: 'إرشاد', images: [a, b]);

  Future<List<String>> run(PostDraft draft) async =>
      describe(await publish(draft, rig.session).toList());

  test('text only: no progress (S3), 6.2 with no media, the answer', () async {
    rig.creates(Right(PostPublished(testPost(id: 31))));

    expect(await run(const PostDraft(text: 'إرشاد')), [
      'answered PostPublished',
    ]);
    expect(rig.lastImageIds(), isEmpty);
  });

  test(
    'images: one after another in her order, progress by bytes across '
    'them (per whole percent), then 6.2 with their ids in that order',
    () async {
      rig
        ..uploads('a.jpg')
        ..uploads('b.jpg')
        ..creates(Right(PostPublished(testPost(id: 31))));

      expect(await run(draft), [
        'up 0', 'up 12', 'up 25', 'up 62', 'up 100', //
        'creating', 'answered PostPublished',
      ]);
      expect(rig.sent, ['a.jpg', 'b.jpg']);
      expect(rig.lastImageIds(), ['id-a.jpg', 'id-b.jpg']);
    },
  );

  test('Retry: an image already up isn\'t sent again, and the request id '
      'is the same while the draft is', () async {
    rig
      ..uploads('a.jpg')
      ..uploads('b.jpg', const Left(OfflineFailure()));
    expect((await run(draft)).last, 'failed');

    rig
      ..uploads('b.jpg')
      ..creates(const Left(OfflineFailure()));
    expect((await run(draft)).last, 'failed');
    rig.creates(Right(PostPublished(testPost(id: 31))));
    expect((await run(draft)).last, 'answered PostPublished');

    expect(rig.sent, ['a.jpg', 'b.jpg', 'b.jpg']);
    expect(rig.requestIds, ['req-1', 'req-1']);
  });

  test('an edited draft gets a new request id; its images already up are '
      'reused', () async {
    rig
      ..uploads('a.jpg')
      ..uploads('b.jpg');
    await run(draft);

    await run(PostDraft(text: 'إرشاد آخر', images: [b, a]));

    expect(rig.sent, ['a.jpg', 'b.jpg']);
    expect(rig.requestIds, ['req-1', 'req-2']);
    expect(rig.lastImageIds(), ['id-b.jpg', 'id-a.jpg']);
  });

  test('her cancel mid-upload: cancelled, no post, what went up is deleted '
      'and sent again next time (S6)', () async {
    rig
      ..uploads('a.jpg')
      ..uploads('b.jpg', const Left(UploadCancelledFailure()));

    expect((await run(draft)).last, 'cancelled');
    await Future<void>.delayed(Duration.zero);
    verify(() => rig.repository.deleteMedia('id-a.jpg')).called(1);
    expect(rig.requestIds, isEmpty);

    rig.uploads('b.jpg');
    await run(draft);
    expect(rig.sent, ['a.jpg', 'b.jpg', 'a.jpg', 'b.jpg']);
  });

  test('cancelled after the last image went up, before 6.2: no post', () async {
    rig
      ..uploads('a.jpg')
      ..uploads('b.jpg');
    when(
      () => rig.repository.uploadImage(
        any(),
        onProgress: any(named: 'onProgress'),
        cancel: any(named: 'cancel'),
      ),
    ).thenAnswer((call) async {
      rig.session.cancel();
      return const Right(MediaUploaded('id-x'));
    });

    expect((await run(PostDraft(text: 't', images: [a]))).last, 'cancelled');
    expect(rig.requestIds, isEmpty);
    verify(() => rig.repository.deleteMedia('id-x')).called(1);
  });

  test(
    'the server refuses one image: that image, and nothing is made',
    () async {
      rig
        ..uploads('a.jpg')
        ..uploads(
          'b.jpg',
          const Right(MediaUploadRefused(MediaRefusal.tooLarge)),
        );

      expect((await run(draft)).last, 'refused b.jpg');
      expect(rig.requestIds, isEmpty);
    },
  );

  test(
    'lost media on 6.2: the answer, and Retry sends every image again',
    () async {
      rig
        ..uploads('a.jpg')
        ..uploads('b.jpg')
        ..creates(const Right(PostMediaLost()));
      expect((await run(draft)).last, 'answered PostMediaLost');

      await run(draft);
      expect(rig.sent, ['a.jpg', 'b.jpg', 'a.jpg', 'b.jpg']);
    },
  );

  test('each attempt has its own cancel, given to every upload', () async {
    rig
      ..uploads('a.jpg')
      ..uploads('b.jpg');
    await run(draft);

    expect(rig.cancels.toSet().length, 1);
    expect(rig.cancels.first, isNotNull);
  });

  test('a video is made ready first (D1); until sub-step 13 uploads it, '
      'the attempt ends as BA-A6, with no post', () async {
    final video = PickedVideo(
      path: 'v.mov',
      container: VideoContainer.quickTime,
      info: clip(),
    );

    expect(await run(PostDraft(text: 'إرشاد', video: video)), [
      'prep 0', 'prep 50', 'prep 100', //
      'answered PostVideoUnavailable',
    ]);
    expect(rig.requestIds, isEmpty);
  });

  test('the composer closed: its compressed copies are deleted', () async {
    await publish.deleteCopies();

    expect(rig.compressor.deletions, 1);
  });
}
