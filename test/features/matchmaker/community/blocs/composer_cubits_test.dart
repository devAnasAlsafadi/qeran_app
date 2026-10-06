import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/community_config.dart';
import 'package:qeran/features/community/domain/entities/post_publish_outcome.dart';
import 'package:qeran/features/community/domain/usecases/create_community_post_usecase.dart';
import 'package:qeran/features/community/domain/usecases/get_community_config_usecase.dart';
import 'package:qeran/features/matchmaker/community/presentation/blocs/composer/post_draft_cubit.dart';
import 'package:qeran/features/matchmaker/community/presentation/blocs/composer/post_publish_cubit.dart';

import '../../../community/fixtures/community_post_fixtures.dart';

class _MockConfig extends Mock implements GetCommunityConfigUseCase {}

class _MockCreate extends Mock implements CreateCommunityPostUseCase {}

void main() {
  group('PostDraftCubit', () {
    late _MockConfig config;
    late PostDraftCubit draft;
    setUp(() {
      config = _MockConfig();
      draft = PostDraftCubit(getConfig: config);
    });
    tearDown(() => draft.close());

    test('the limits are read fresh on opening (K20)', () async {
      when(() => config(fresh: true)).thenAnswer(
        (_) async => const Right(CommunityConfig(postTextMaxLength: 2000)),
      );

      await draft.loadConfig();

      verify(() => config(fresh: true)).called(1);
      expect(draft.state.maxLength, 2000);
    });

    test('«نشر» needs text — counted after trimming — within the limit '
        '(C2, C7)', () async {
      when(() => config(fresh: true)).thenAnswer(
        (_) async => const Right(CommunityConfig(postTextMaxLength: 5)),
      );
      await draft.loadConfig();

      draft.edit('   ');
      expect([draft.state.canPublish, draft.state.isEmpty], [false, true]);
      draft.edit('  abcde  ');
      expect([draft.state.length, draft.state.canPublish], [5, true]);
      draft.edit('abcdef');
      expect([draft.state.tooLong, draft.state.canPublish], [true, false]);
    });

    test('no limits read: the server checks the length (S19)', () async {
      when(
        () => config(fresh: true),
      ).thenAnswer((_) async => const Left(OfflineFailure()));
      await draft.loadConfig();

      draft.edit(List.filled(3000, 'a').join());

      expect(draft.state.maxLength, isNull);
      expect(draft.state.canPublish, isTrue);
    });

    test('a refusal stands until she edits the text (BA-A7)', () {
      draft.edit('رقم');
      draft.refused();
      expect(draft.state.rejected, isTrue);

      draft.edit('رقم ');
      expect(draft.state.rejected, isFalse);
    });
  });

  group('PostPublishCubit', () {
    late _MockCreate create;
    late PostPublishCubit publish;
    var ids = 0;
    setUp(() {
      create = _MockCreate();
      publish = PostPublishCubit(
        createPost: create,
        newRequestId: () => 'req-${++ids}',
      );
    });
    tearDown(() => publish.close());

    void answers(Either<Failure, PostPublishOutcome> answer) => when(
      () => create(
        text: any(named: 'text'),
        clientRequestId: any(named: 'clientRequestId'),
      ),
    ).thenAnswer((_) async => answer);

    test('published: the post, sent trimmed (D5)', () async {
      answers(Right(PostPublished(testPost(id: 31))));

      await publish.publish('  إرشاد  ');

      expect(publish.state.status, PublishStatus.published);
      expect(publish.state.post?.id, 31);
      verify(
        () => create(
          text: 'إرشاد',
          clientRequestId: any(named: 'clientRequestId'),
        ),
      ).called(1);
    });

    test('the filter, and new guidelines', () async {
      answers(const Right(PostRejected()));
      await publish.publish('a');
      expect(publish.state.status, PublishStatus.rejected);

      answers(const Right(PostGuidelinesRequired()));
      await publish.publish('b');
      expect(publish.state.status, PublishStatus.guidelinesRequired);
    });

    test('a retry of the same text keeps its request id; an edited one '
        'gets a new one (W16)', () async {
      answers(const Left(OfflineFailure()));
      final sent = <String>[];
      when(
        () => create(
          text: any(named: 'text'),
          clientRequestId: any(named: 'clientRequestId'),
        ),
      ).thenAnswer((call) async {
        sent.add(call.namedArguments[#clientRequestId] as String);
        return const Left(OfflineFailure());
      });

      await publish.publish('نص');
      expect(publish.state.status, PublishStatus.failed);
      await publish.publish('نص');
      await publish.publish('نص آخر');

      expect(sent[0], sent[1]);
      expect(sent[2], isNot(sent[1]));
    });

    test('a second tap while it publishes sends nothing more', () async {
      final answer = Completer<Either<Failure, PostPublishOutcome>>();
      when(
        () => create(
          text: any(named: 'text'),
          clientRequestId: any(named: 'clientRequestId'),
        ),
      ).thenAnswer((_) => answer.future);

      final first = publish.publish('a');
      expect(publish.state.busy, isTrue);
      await publish.publish('a');
      answer.complete(Right(PostPublished(testPost())));
      await first;

      verify(
        () => create(
          text: any(named: 'text'),
          clientRequestId: any(named: 'clientRequestId'),
        ),
      ).called(1);
    });
  });
}
