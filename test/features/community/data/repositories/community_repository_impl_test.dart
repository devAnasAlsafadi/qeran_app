import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/community/data/datasources/community_remote_datasource.dart';
import 'package:qeran/features/community/data/models/community_config_model.dart';
import 'package:qeran/features/community/data/repositories/community_repository_impl.dart';
import 'package:qeran/features/community/domain/entities/comment_submit_outcome.dart';
import 'package:qeran/features/community/domain/entities/community_post_change.dart';

import '../../fixtures/community_fixtures.dart';
import '../../fixtures/community_mock_harness.dart';

class _MockDataSource extends Mock implements CommunityRemoteDataSource {}

T right<T>(Either<Failure, T> e) => e.fold((f) => fail('Left: $f'), (r) => r);

void main() {
  late CommunityRepositoryImpl repo;
  late int postId;

  setUp(() async {
    final ds = seededMock(accepted: false);
    repo = CommunityRepositoryImpl(ds);
    postId = right(await repo.getFeed(page: 1, pageSize: 20)).items.first.id;
  });

  group('postChanges', () {
    test('a re-read announces the fresh post', () async {
      final next = repo.postChanges.first;

      final post = right(await repo.getPost(postId));

      final change = await next as CommunityPostUpdated;
      expect(change.post, post);
    });

    test("a like announces the server's count", () async {
      final next = repo.postChanges.first;

      final like = right(await repo.setPostLike(postId, liked: false));

      final change = await next as CommunityPostLikeChanged;
      expect((change.postId, change.like), (postId, like));
    });

    test('POST_NOT_FOUND announces the post gone and stays a failure', () async {
      final next = repo.postChanges.first;

      final result = await repo.getPost(1);

      expect(result.isLeft(), isTrue);
      expect((await next as CommunityPostGone).postId, 1);
    });
  });

  group('comment outcomes on the Right', () {
    test('guidelines not accepted → CommentGuidelinesRequired', () async {
      expect(right(await repo.createComment(postId, 'x')),
          isA<CommentGuidelinesRequired>());
    });

    test('accepted → CommentPosted with the server comment', () async {
      final version = right(await repo.getGuidelines()).version;
      right(await repo.acceptGuidelines(version));

      final outcome = right(await repo.createComment(postId, 'شكراً'));

      expect((outcome as CommentPosted).comment.isMine, isTrue);
    });

    test('a reply to a missing comment → CommentParentGone', () async {
      expect(right(await repo.createReply(1, 'x')), isA<CommentParentGone>());
    });

    test('an unmapped failure stays on the Left', () async {
      final version = right(await repo.getGuidelines()).version;
      right(await repo.acceptGuidelines(version));

      final result = await repo.createComment(postId, '   ');

      expect(result.isLeft(), isTrue); // VALIDATION_ERROR
    });
  });

  group('config, once per session', () {
    late _MockDataSource ds;
    setUp(() => ds = _MockDataSource());

    test('a success is kept: the second read never calls the server', () async {
      when(() => ds.getConfig())
          .thenAnswer((_) async => CommunityConfigModel.fromJson(config()));
      final repo = CommunityRepositoryImpl(ds);

      right(await repo.getConfig());
      final again = right(await repo.getConfig());

      expect(again.commentMaxLength, 500);
      verify(() => ds.getConfig()).called(1);
    });

    test('a failure is not kept: the next read tries again', () async {
      var calls = 0;
      when(() => ds.getConfig()).thenAnswer((_) async {
        if (calls++ == 0) throw const OfflineException();
        return CommunityConfigModel.fromJson(config());
      });
      final repo = CommunityRepositoryImpl(ds);

      expect(await repo.getConfig(), const Left(OfflineFailure()));
      expect(right(await repo.getConfig()).commentMaxLength, 500);
    });
  });
}
