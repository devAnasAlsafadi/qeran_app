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
import 'package:qeran/features/community/domain/usecases/create_community_post_usecase.dart';
import 'package:qeran/features/community/domain/usecases/get_community_config_usecase.dart';
import 'package:qeran/features/matchmaker/account/domain/usecases/get_me_usecase.dart';
import 'package:qeran/features/matchmaker/community/presentation/blocs/composer/post_draft_cubit.dart';
import 'package:qeran/features/matchmaker/community/presentation/blocs/composer/post_publish_cubit.dart';
import 'package:qeran/features/matchmaker/community/presentation/blocs/guidelines/matchmaker_guidelines_status.dart';
import 'package:qeran/features/matchmaker/community/presentation/screens/start_new_post.dart';

import '../../community/presentation/screens/guidelines_rig.dart';
import '../account/matchmaker_me_fixtures.dart';
import 'community_screen_rig.dart';

class _MockConfig extends Mock implements GetCommunityConfigUseCase {}

class _MockCreate extends Mock implements CreateCommunityPostUseCase {}

class _MockGetMe extends Mock implements GetMeUseCase {}

/// Her composer over scripted answers: the limits ([maxLength]), whether
/// she still owes the posting guidelines ([owed]), and what publishing
/// says. Request ids are `req-1`, `req-2`… in order; [sentIds] keeps them.
class ComposerHarness {
  ComposerHarness({int? maxLength = 2000, bool owed = false}) {
    limitText(maxLength);
    when(() => getMe()).thenAnswer((_) async => Right(meWith(accepted: !owed)));
    sl.registerFactory<PostDraftCubit>(() => PostDraftCubit(getConfig: config));
    sl.registerFactory<PostPublishCubit>(
      () => PostPublishCubit(createPost: create, newRequestId: _nextId),
    );
    sl.registerSingleton(status);
    guidelines.accepts([const Right(GuidelinesAcceptance.accepted)]);
  }

  final config = _MockConfig();
  final create = _MockCreate();
  final getMe = _MockGetMe();
  late final status = MatchmakerGuidelinesStatus(getMe: getMe);
  late final guidelines = GuidelinesHarness(
    onAccepted: status.markAccepted,
    instanceName: CommunityViewer.matchmaker.name,
  );
  final sentIds = <String>[];
  int _ids = 0;

  /// What the composer answered: the post, or null once it closed without.
  CommunityPost? result;
  bool closed = false;

  String _nextId() => 'req-${++_ids}';

  /// The server's `postTextMaxLength` as the composer will read it.
  void limitText(int? maxLength) => when(() => config(fresh: true)).thenAnswer(
    (_) async => Right(CommunityConfig(postTextMaxLength: maxLength)),
  );

  /// Each publish answers [answer] and keeps its request id.
  void publishes(Either<Failure, PostPublishOutcome> answer) =>
      when(
        () => create(
          text: any(named: 'text'),
          clientRequestId: any(named: 'clientRequestId'),
        ),
      ).thenAnswer((call) async {
        sentIds.add(call.namedArguments[#clientRequestId] as String);
        return answer;
      });
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
