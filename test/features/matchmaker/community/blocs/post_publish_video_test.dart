import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/domain/entities/media_refusal.dart';
import 'package:qeran/features/community/domain/entities/picked_video.dart';
import 'package:qeran/features/community/domain/entities/post_draft.dart';
import 'package:qeran/features/community/domain/usecases/publish_community_post_usecase.dart';
import 'package:qeran/features/matchmaker/community/presentation/blocs/composer/post_publish_cubit.dart';

import '../../../community/domain/fake_video_compressor.dart';
import '../../../community/domain/publish_rig.dart';

const _mb = 1024 * 1024;

/// Publishing her video, up to the upload (sub-step 13): D1, Q2, Q3.
void main() {
  late PublishRig rig;
  late PostPublishCubit publish;
  setUp(() {
    rig = PublishRig();
    publish = PostPublishCubit(
      publish: PublishCommunityPostUseCase(rig.repository, rig.compressor),
      newRequestId: () => 'req',
    );
  });
  tearDown(() => publish.close());

  PostDraft draft({int? maxBytes}) => PostDraft(
    text: '  إرشاد ',
    video: PickedVideo(
      path: 'v.mov',
      container: VideoContainer.quickTime,
      info: clip(),
    ),
    maxVideoBytes: maxBytes,
  );

  List<(PublishStatus, double?)> seen(List<PostPublishState> states) => [
    for (final s in states) (s.status, s.progress),
  ];

  test('D1: compressing from 0 with its progress, busy and cancellable; '
      'until sub-step 13 the attempt then fails as BA-A6', () async {
    final states = <PostPublishState>[];
    publish.stream.listen(states.add);

    await publish.publish(draft());

    expect(seen(states), [
      (PublishStatus.compressing, 0.0),
      (PublishStatus.compressing, 0.5),
      (PublishStatus.compressing, 1.0),
      (PublishStatus.failed, null),
    ]);
    expect(states.where((s) => s.busy && s.cancellable).length, 3);
  });

  test('a retry with the copy ready doesn\'t start at «تجهيز»', () async {
    await publish.publish(draft());
    final states = <PostPublishState>[];
    publish.stream.listen(states.add);

    await publish.publish(draft());

    expect(states.first.status, PublishStatus.uploading);
    expect(rig.compressor.compressed, ['v.mov']);
  });

  test('her cancel while it compresses: back to the draft', () async {
    rig.compressor.hold = Completer();

    final publishing = publish.publish(draft());
    await pumpEventQueue();
    publish.cancel();
    await publishing;

    expect(publish.state.status, PublishStatus.idle);
  });

  test('Q3: over the size — refused, which video, and the size of the file '
      'that would have gone up', () async {
    await publish.publish(draft(maxBytes: 3 * _mb));

    expect(publish.state.status, PublishStatus.refused);
    expect(publish.state.refusal, MediaRefusal.tooLarge);
    expect(publish.state.refusedPath, 'v.mov');
    expect(publish.state.refusedBytes, 4 * _mb);
  });

  test('the composer closed: the compressed copies are deleted', () async {
    await publish.close();

    expect(rig.compressor.deletions, 1);
  });
}
