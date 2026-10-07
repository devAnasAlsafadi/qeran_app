import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/media_refusal.dart';
import 'package:qeran/features/community/domain/entities/media_upload_outcome.dart';
import 'package:qeran/features/community/domain/entities/post_draft.dart';
import 'package:qeran/features/community/domain/entities/post_publish_outcome.dart';
import 'package:qeran/features/community/domain/usecases/publish_community_post_usecase.dart';
import 'package:qeran/features/matchmaker/community/presentation/blocs/composer/post_publish_cubit.dart';

import '../../../community/domain/publish_rig.dart';
import '../../../community/fixtures/community_post_fixtures.dart';

void main() {
  late PublishRig rig;
  late PostPublishCubit publish;
  late int ids;
  setUp(() {
    ids = 0;
    rig = PublishRig();
    publish = PostPublishCubit(
      publish: PublishCommunityPostUseCase(rig.repository, rig.compressor),
      newRequestId: () => 'req-${++ids}',
    );
  });
  tearDown(() => publish.close());

  PostDraft text(String value) => PostDraft(text: value);
  final withImage = PostDraft(text: 'إرشاد', images: [pickedImage('a.jpg')]);

  test('published: the post, sent trimmed, no strip (D5, S3)', () async {
    rig.creates(Right(PostPublished(testPost(id: 31))));
    final states = <PostPublishState>[];
    publish.stream.listen(states.add);

    await publish.publish(text('  إرشاد  '));

    expect(states.first.progress, isNull);
    expect(publish.state.status, PublishStatus.published);
    expect(publish.state.post?.id, 31);
    verify(
      () => rig.repository.createPost(
        text: 'إرشاد',
        clientRequestId: any(named: 'clientRequestId'),
        imageMediaIds: const [],
      ),
    ).called(1);
  });

  test('the filter, new guidelines, the length, lost media', () async {
    final cases = {
      const PostRejected(): PublishStatus.rejected,
      const PostGuidelinesRequired(): PublishStatus.guidelinesRequired,
      const PostTextInvalid(): PublishStatus.textInvalid,
      const PostMediaLost(): PublishStatus.failed,
    };
    for (final MapEntry(key: outcome, value: status) in cases.entries) {
      rig.creates(Right(outcome));
      await publish.publish(text('a'));
      expect(publish.state.status, status, reason: '$outcome');
    }
  });

  test('a retry of the same text keeps its request id; an edited one '
      'gets a new one (W16)', () async {
    await publish.publish(text('نص'));
    expect(publish.state.status, PublishStatus.failed);
    await publish.publish(text('نص'));
    await publish.publish(text('نص آخر'));

    expect(rig.requestIds, ['req-1', 'req-1', 'req-2']);
  });

  test('a second tap while it publishes sends nothing more', () async {
    final answer = Completer<Either<Failure, PostPublishOutcome>>();
    when(
      () => rig.repository.createPost(
        text: any(named: 'text'),
        clientRequestId: any(named: 'clientRequestId'),
        imageMediaIds: any(named: 'imageMediaIds'),
      ),
    ).thenAnswer((_) => answer.future);

    final first = publish.publish(text('a'));
    expect(publish.state.busy, isTrue);
    await publish.publish(text('a'));
    answer.complete(Right(PostPublished(testPost())));
    await first;

    verify(
      () => rig.repository.createPost(
        text: any(named: 'text'),
        clientRequestId: any(named: 'clientRequestId'),
        imageMediaIds: any(named: 'imageMediaIds'),
      ),
    ).called(1);
  });

  test('with an image: uploading with progress, then made at 100 % with no '
      'cancel left, then published', () async {
    rig
      ..uploads('a.jpg')
      ..creates(Right(PostPublished(testPost(id: 31))));
    final states = <PostPublishState>[];
    publish.stream.listen(states.add);

    await publish.publish(withImage);

    expect(
      [for (final s in states) (s.status, s.progress)],
      [
        (PublishStatus.uploading, 0.0),
        (PublishStatus.uploading, 0.5),
        (PublishStatus.uploading, 1.0),
        (PublishStatus.publishing, 1.0),
        (PublishStatus.published, null),
      ],
    );
    expect(states.where((s) => s.cancellable).length, 3);
  });

  test('cancel while it uploads: back to the draft, nothing made', () async {
    when(
      () => rig.repository.uploadImage(
        any(),
        onProgress: any(named: 'onProgress'),
        cancel: any(named: 'cancel'),
      ),
    ).thenAnswer((call) async {
      await (call.namedArguments[#cancel] as UploadCancel).whenCancelled;
      return const Left(UploadCancelledFailure());
    });

    final publishing = publish.publish(withImage);
    await Future<void>.delayed(Duration.zero);
    publish.cancel();
    await publishing;

    expect(publish.state.status, PublishStatus.idle);
    expect(rig.requestIds, isEmpty);
  });

  test('the server refused the image: which, and why', () async {
    rig.uploads(
      'a.jpg',
      const Right(MediaUploadRefused(MediaRefusal.invalidType)),
    );

    await publish.publish(withImage);

    expect(publish.state.status, PublishStatus.refused);
    expect(publish.state.refusedPath, 'a.jpg');
    expect(publish.state.refusal, MediaRefusal.invalidType);
  });
}
