import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/community_config.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/domain/entities/community_viewer.dart';
import 'package:qeran/features/community/domain/entities/guidelines_acceptance.dart';
import 'package:qeran/features/community/domain/entities/post_publish_outcome.dart';
import 'package:qeran/features/community/domain/usecases/get_community_config_usecase.dart';
import 'package:qeran/features/community/domain/usecases/inspect_picked_image_usecase.dart';
import 'package:qeran/features/community/domain/usecases/inspect_picked_video_usecase.dart';
import 'package:qeran/features/community/domain/usecases/publish_community_post_usecase.dart';
import 'package:qeran/features/community/presentation/video/community_video_player.dart';
import 'package:qeran/features/matchmaker/account/domain/usecases/get_me_usecase.dart';
import 'package:qeran/features/matchmaker/community/presentation/blocs/composer/post_draft_cubit.dart';
import 'package:qeran/features/matchmaker/community/presentation/blocs/composer/post_publish_cubit.dart';
import 'package:qeran/features/matchmaker/community/presentation/blocs/guidelines/matchmaker_guidelines_status.dart';
import 'package:qeran/features/matchmaker/community/presentation/screens/start_new_post.dart';
import 'package:qeran/features/matchmaker/community/presentation/services/community_media_picker.dart';

import '../../community/domain/publish_rig.dart';
import '../../community/presentation/screens/guidelines_rig.dart';
import '../../community/presentation/widgets/video/video_rig.dart';
import '../account/matchmaker_me_fixtures.dart';
import 'community_screen_rig.dart';
import 'composer_media_fakes.dart';

class _MockConfig extends Mock implements GetCommunityConfigUseCase {}

class _MockGetMe extends Mock implements GetMeUseCase {}

/// Her composer over scripted answers: the limits, whether she still owes
/// the posting guidelines ([owed]), what the picker returns and what each
/// file is, and what the server says. Request ids are `req-1`, `req-2`…;
/// [sentIds] keeps each 6.2's.
class ComposerHarness {
  ComposerHarness({int? maxLength = 2000, bool owed = false}) {
    limitText(maxLength);
    when(() => getMe()).thenAnswer((_) async => Right(meWith(accepted: !owed)));
    sl.registerFactory<PostDraftCubit>(
      () => PostDraftCubit(
        getConfig: config,
        inspectImage: InspectPickedImageUseCase(inspector),
        inspectVideo: InspectPickedVideoUseCase(inspector, compressor),
      ),
    );
    sl.registerSingleton<CommunityLocalVideoPlayerFactory>(_player);
    sl.registerFactory<PostPublishCubit>(
      () => PostPublishCubit(
        publish: PublishCommunityPostUseCase(publishing.repository),
        newRequestId: _nextId,
      ),
    );
    sl.registerSingleton<CommunityMediaPicker>(picker);
    sl.registerSingleton(status);
    guidelines.accepts([const Right(GuidelinesAcceptance.accepted)]);
  }

  final config = _MockConfig();
  final getMe = _MockGetMe();
  final publishing = PublishRig();
  final inspector = FakeInspector();
  final compressor = FakeCompressor();

  /// Every preview's player, in order.
  final players = <FakePlayer>[];
  CommunityVideoPlayer _player(String path) {
    final player = FakePlayer(Uri.file(path));
    players.add(player);
    return player;
  }

  final picker = FakePicker();
  late final status = MatchmakerGuidelinesStatus(getMe: getMe);
  late final guidelines = GuidelinesHarness(
    onAccepted: status.markAccepted,
    instanceName: CommunityViewer.matchmaker.name,
  );
  int _ids = 0;

  /// What the composer answered: the post, or null once it closed without.
  CommunityPost? result;
  bool closed = false;

  String _nextId() => 'req-${++_ids}';

  /// Each 6.2's request id, in order.
  List<String> get sentIds => publishing.requestIds;

  /// The server's limits as the composer will read them.
  void configure(CommunityConfig limits) =>
      when(() => config(fresh: true)).thenAnswer((_) async => Right(limits));

  /// Only `postTextMaxLength`.
  void limitText(int? maxLength) =>
      configure(CommunityConfig(postTextMaxLength: maxLength));

  /// Each publish answers [answer].
  void publishes(Either<Failure, PostPublishOutcome> answer) =>
      publishing.creates(answer);
}

/// «منشور جديد» from a screen with one button, as her app starts it.
Future<void> startComposer(
  WidgetTester tester,
  ComposerHarness h, {
  Locale locale = const Locale('en'),
}) async {
  await pumpHerApp(
    tester,
    Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () async {
            h.result = await startNewPost(context);
            h.closed = true;
          },
          child: const Text('open'),
        ),
      ),
    ),
    locale: locale,
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
