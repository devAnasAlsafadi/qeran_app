import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/features/community/domain/entities/community_config.dart';
import 'package:qeran/features/community/domain/entities/media_refusal.dart';
import 'package:qeran/features/community/domain/entities/picked_video.dart';
import 'package:qeran/features/community/domain/usecases/get_community_config_usecase.dart';
import 'package:qeran/features/community/domain/usecases/inspect_picked_image_usecase.dart';
import 'package:qeran/features/community/domain/usecases/inspect_picked_video_usecase.dart';
import 'package:qeran/features/matchmaker/community/presentation/blocs/composer/post_draft_cubit.dart';

import '../composer_media_fakes.dart';

class _MockConfig extends Mock implements GetCommunityConfigUseCase {}

const _video = CommunityConfig(
  postTextMaxLength: 2000,
  maxImagesPerPost: 10,
  maxVideoDurationSeconds: 60,
  allowedVideoTypes: ['mp4', 'mov'],
  videoEnabled: true,
);

/// Her video in the draft (C6, BA-A4, BA-A9, D11).
void main() {
  late _MockConfig config;
  late FakeInspector inspector;
  late FakeCompressor compressor;
  late PostDraftCubit draft;
  setUp(() {
    config = _MockConfig();
    inspector = FakeInspector();
    compressor = FakeCompressor();
    draft = PostDraftCubit(
      getConfig: config,
      inspectImage: InspectPickedImageUseCase(inspector),
      inspectVideo: InspectPickedVideoUseCase(inspector, compressor),
    );
  });
  tearDown(() => draft.close());

  Future<void> limits(CommunityConfig value) async {
    when(() => config(fresh: true)).thenAnswer((_) async => Right(value));
    await draft.loadConfig();
  }

  test('offered only when the server says so (BA-A4); limits not read: '
      'not offered (S19)', () async {
    expect(draft.state.videoOffered, isFalse);
    await limits(const CommunityConfig(videoEnabled: false));
    expect([draft.state.videoOffered, draft.state.canAddVideo], [false, false]);
    await limits(_video);
    expect([draft.state.videoOffered, draft.state.canAddVideo], [true, true]);
  });

  test('one video: images and a second video can\'t be added; removing it '
      'brings both back (D11)', () async {
    await limits(_video);

    await draft.addVideo('clip.mp4');
    expect(draft.state.video?.path, 'clip.mp4');
    expect([draft.state.canAddImages, draft.state.canAddVideo], [false, false]);
    expect(draft.state.isEmpty, isFalse);

    draft.removeVideo();
    expect(draft.state.video, isNull);
    expect([draft.state.canAddImages, draft.state.canAddVideo], [true, true]);
  });

  test('with images, no video', () async {
    await limits(_video);
    await draft.addImages(['a.jpg']);

    expect(draft.state.canAddVideo, isFalse);
  });

  test('the length, rounded to the nearest second (S4): 60.4 s goes in at '
      'a 60 s limit; 60.6 s stays out with BA-A9', () async {
    await limits(_video);
    compressor.infos['ok.mp4'] = clip(seconds: 60.4);
    compressor.infos['long.mp4'] = clip(seconds: 60.6);

    await draft.addVideo('ok.mp4');
    expect(draft.state.video?.durationSeconds, 60);
    draft.removeVideo();

    await draft.addVideo('long.mp4');
    expect(draft.state.video, isNull);
    expect(draft.state.notice, const VideoTooLong(seconds: 61, maxSeconds: 60));
  });

  test('a container the server wouldn\'t take, or a file that can\'t be '
      'read, stays out (C10)', () async {
    await limits(
      const CommunityConfig(videoEnabled: true, allowedVideoTypes: ['mp4']),
    );
    inspector.videos['a.mov'] = VideoContainer.quickTime;
    inspector.videos['a.3gp'] = null;
    compressor.infos['broken.mp4'] = null;

    for (final path in ['a.mov', 'a.3gp', 'broken.mp4']) {
      await draft.addVideo(path);
      expect(draft.state.video, isNull, reason: path);
      expect(draft.state.notice, const UnsupportedFile(), reason: path);
    }
  });

  test('a video never stands in for text: «نشر» once there is some', () async {
    await limits(_video);
    await draft.addVideo('clip.mp4');
    expect(draft.state.canPublish, isFalse);

    draft.edit('إرشاد');
    expect(draft.state.canPublish, isTrue);
  });

  test('the server’s own length check (MEDIA_TOO_LONG on 6.8): BA-A9 with '
      'her video’s length; it leaves the draft', () async {
    await limits(_video);
    compressor.infos['edge.mp4'] = clip(seconds: 60.4);
    await draft.addVideo('edge.mp4');

    draft.mediaRefused(path: 'edge.mp4', refusal: MediaRefusal.tooLong);

    expect(draft.state.video, isNull);
    expect(
      draft.state.notice,
      const VideoTooLong(seconds: 60, maxSeconds: 60),
    );
  });

  test('Q3: her video over the size once prepared leaves the draft, with the '
      'size of what would have gone up; another refusal is C10', () async {
    await limits(
      const CommunityConfig(videoEnabled: true, maxVideoSizeBytes: 300),
    );
    await draft.addVideo('clip.mp4');

    draft.mediaRefused(
      path: 'clip.mp4',
      refusal: MediaRefusal.tooLarge,
      sizeBytes: 320,
    );
    expect(draft.state.video, isNull);
    expect(
      draft.state.notice,
      const VideoTooLarge(sizeBytes: 320, maxBytes: 300),
    );

    await draft.addVideo('clip.mp4');
    draft.mediaRefused(path: 'clip.mp4', refusal: MediaRefusal.invalidType);
    expect(draft.state.video, isNull);
    expect(draft.state.notice, const UnsupportedFile());
  });
}
