import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/community_like_state.dart';
import 'package:qeran/features/community/domain/entities/community_post_change.dart';
import 'package:qeran/features/community/presentation/blocs/post/community_post_state.dart';

import '../../../fixtures/community_post_fixtures.dart';
import 'post_cubit_harness.dart';

const _liked = CommunityLikeState(likeCount: 6, likedByMe: true);

void main() {
  group('the like', () {
    late PostHarness h;
    setUp(() => h = PostHarness(post: testPost(likeCount: 5)));
    tearDown(() => h.dispose());

    (int, bool) like() => (h.post.likeCount, h.post.likedByMe);
    CommunityPostEvent event() => (h.cubit.state as CommunityPostReady).event;

    test('shows at once, then settles on the server\'s answer', () async {
      final answer = Completer<Either<Failure, CommunityLikeState>>();
      when(() => h.setLike(1, liked: true)).thenAnswer((_) => answer.future);

      final liking = h.cubit.toggleLike();
      expect(like(), (6, true));

      answer.complete(
        const Right(CommunityLikeState(likeCount: 9, likedByMe: true)),
      );
      await liking;
      expect(like(), (9, true));
    });

    test('failed: taken back, and the screen says so', () async {
      h.likeAnswers(const Left(ServerFailure(message: 'x')));

      await h.cubit.toggleLike();

      expect(like(), (5, false));
      expect(event(), CommunityPostEvent.likeFailed);
    });

    test('turned away as not approved: taken back, and told why', () async {
      h.likeAnswers(
        const Left(
          CodedServerFailure(message: 'x', errorCode: 'PROFILE_NOT_APPROVED'),
        ),
      );

      await h.cubit.toggleLike();

      expect(like(), (5, false));
      expect(event(), CommunityPostEvent.readOnlyLike);
    });

    test('read-only: told why, and nothing is sent (D9)', () async {
      await h.cubit.toggleLike(readOnly: true);

      expect(event(), CommunityPostEvent.readOnlyLike);
      expect(like(), (5, false));
      verifyNever(() => h.setLike(any(), liked: any(named: 'liked')));
    });

    test('a second tap waits for the first answer', () async {
      final answer = Completer<Either<Failure, CommunityLikeState>>();
      when(
        () => h.setLike(1, liked: any(named: 'liked')),
      ).thenAnswer((_) => answer.future);

      final first = h.cubit.toggleLike();
      await h.cubit.toggleLike();
      answer.complete(const Right(_liked));
      await first;

      verify(() => h.setLike(1, liked: true)).called(1);
      expect(like(), (6, true));
    });

    test('the post gone while the like is on its way: nothing to take '
        'back', () async {
      final answer = Completer<Either<Failure, CommunityLikeState>>();
      when(
        () => h.setLike(1, liked: any(named: 'liked')),
      ).thenAnswer((_) => answer.future);

      final liking = h.cubit.toggleLike();
      await h.announce(const CommunityPostGone(1));
      answer.complete(const Left(postNotFound));
      await liking;

      expect(h.cubit.state, const CommunityPostRemoved());
    });
  });
}
