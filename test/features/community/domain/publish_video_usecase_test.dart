import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/media_refusal.dart';
import 'package:qeran/features/community/domain/entities/media_upload_outcome.dart';
import 'package:qeran/features/community/domain/entities/post_draft.dart';
import 'package:qeran/features/community/domain/entities/post_publish_outcome.dart';
import 'package:qeran/features/community/domain/usecases/publish_community_post_usecase.dart';

import '../fixtures/community_post_fixtures.dart';
import 'publish_rig.dart';

final _now = DateTime.utc(2026, 10, 7, 12);

/// Publishing her video (plan §3.4: D1, D2, D3, BA-A6, S6).
void main() {
  late PublishRig rig;
  late PublishCommunityPostUseCase publish;
  setUp(() {
    rig = PublishRig()..creates(Right(PostPublished(testPost(id: 31))));
    publish = PublishCommunityPostUseCase(
      rig.repository,
      rig.compressor,
      now: () => _now,
    );
  });

  final draft = PostDraft(text: 'إرشاد', video: pickedVideo('v.mov'));

  Future<List<String>> run([PostDraft? value]) async =>
      describe(await publish(value ?? draft, rig.session).toList());

  test('made ready, granted for the copy at the length she was checked at, '
      'sent with tus, then 6.2 with its id', () async {
    expect(await run(), [
      'prep 0', 'prep 50', 'prep 100', //
      'up 0', 'up 50', 'up 100', //
      'creating', 'answered PostPublished',
    ]);
    expect(rig.video.grantedFiles, ['v.mov.mp4']);
    expect(rig.video.durations, [30]);
    expect(rig.lastVideoId(), 'v-1');
  });

  test('Retry after the upload broke: the same grant, tus goes on from its '
      'upload, the same request id', () async {
    rig
      ..video.tus(const Left(OfflineFailure()))
      ..creates(const Left(OfflineFailure()));
    expect((await run()).last, 'failed');

    rig.video.tus();
    expect((await run()).last, 'failed');
    rig.creates(Right(PostPublished(testPost(id: 31))));
    expect((await run()).last, 'answered PostPublished');

    expect(rig.video.sentUnder, ['v-1', 'v-1']);
    expect(rig.video.resumedAt, [null, Uri.parse('https://tus/v-1')]);
    expect(rig.requestIds, ['req-1', 'req-1']);
    expect(rig.compressor.compressed, ['v.mov']);
  });

  test('a grant about to run out is replaced before the rest goes up, and '
      'its media deleted', () async {
    final soon = _now.add(const Duration(minutes: 5));
    rig.video.grant = (id) => videoGrant(id, expiresAt: soon);
    rig.video.tus(const Left(OfflineFailure()));
    await run();

    rig.video.tus();
    await run();

    expect(rig.video.sentUnder, ['v-1', 'v-2']);
    expect(rig.video.resumedAt, [null, null]);
    verify(() => rig.repository.deleteMedia('v-1')).called(1);
  });

  test('her cancel during the upload: cancelled, its media deleted (S6); '
      'Retry starts over under a new grant, with the same copy', () async {
    rig.video.tus(const Left(UploadCancelledFailure()));

    expect((await run()).last, 'cancelled');
    await Future<void>.delayed(Duration.zero);
    verify(() => rig.repository.deleteMedia('v-1')).called(1);

    rig.video.tus();
    expect((await run()).last, 'answered PostPublished');
    expect(rig.video.sentUnder, ['v-1', 'v-2']);
    expect(rig.compressor.compressed, ['v.mov']);
  });

  test(
    '6.8 refuses it (MEDIA_TOO_LONG): which video, and nothing sent',
    () async {
      rig.video.grants(const Right(MediaUploadRefused(MediaRefusal.tooLong)));

      expect((await run()).last, 'refused v.mov tooLong ${4 * 1024 * 1024}');
      expect(rig.video.sentUnder, isEmpty);
      expect(rig.requestIds, isEmpty);
    },
  );

  test('the video service down at 6.8 or at 6.2 (BA-A6): Retry keeps the '
      'request id, and a file already up isn\'t sent again', () async {
    rig.video.grants(const Right(MediaVideoUnavailable()));
    expect((await run()).last, 'answered PostVideoUnavailable');

    rig
      ..video.grants()
      ..creates(const Right(PostVideoUnavailable()));
    expect((await run()).last, 'answered PostVideoUnavailable');
    rig.creates(Right(PostPublished(testPost(id: 31))));
    expect(await run(), ['up 100', 'creating', 'answered PostPublished']);

    expect(rig.video.sentUnder, ['v-1']);
    expect(rig.requestIds, ['req-1', 'req-1']);
  });

  test('lost media on 6.2: Retry asks a new grant and sends the file again '
      'from the start', () async {
    rig.creates(const Right(PostMediaLost()));
    await run();

    rig.creates(Right(PostPublished(testPost(id: 31))));
    await run();

    expect(rig.video.sentUnder, ['v-1', 'v-2']);
    expect(rig.video.resumedAt, [null, null]);
  });
}
