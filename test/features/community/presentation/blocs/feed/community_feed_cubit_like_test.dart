import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/community_like_state.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/domain/entities/community_post_change.dart';
import 'package:qeran/features/community/presentation/blocs/feed/community_feed_state.dart';

import '../../../fixtures/community_post_fixtures.dart';
import 'feed_cubit_harness.dart';

const _liked = CommunityLikeState(likeCount: 6, likedByMe: true);

(int, bool) _like(FeedHarness h, int id) {
  final post = h.cubit.state.posts.firstWhere((p) => p.id == id);
  return (post.likeCount, post.likedByMe);
}

void main() {
  late FeedHarness h;
  setUp(() async {
    h = FeedHarness();
    h.page(1, [testPost(id: 1, likeCount: 5), testPost(id: 2)]);
    await h.cubit.load();
  });
  tearDown(() => h.dispose());

  test('a like shows at once, then settles on the server\'s answer', () async {
    final answer = Completer<Either<Failure, CommunityLikeState>>();
    when(() => h.setLike(1, liked: true)).thenAnswer((_) => answer.future);

    final liking = h.cubit.toggleLike(1);
    expect(_like(h, 1), (6, true));

    answer.complete(
      const Right(CommunityLikeState(likeCount: 9, likedByMe: true)),
    );
    await liking;
    expect(_like(h, 1), (9, true));
  });

  test('a failed like is taken back, and the feed says so (B13)', () async {
    h.likeAnswers(1, const Left(ServerFailure(message: 'x')));

    await h.cubit.toggleLike(1);

    expect(_like(h, 1), (5, false));
    expect(h.cubit.state.event, CommunityFeedEvent.likeFailed);
  });

  test('turned away as not approved: taken back, and told why', () async {
    h.likeAnswers(
      1,
      const Left(
        CodedServerFailure(message: 'x', errorCode: 'PROFILE_NOT_APPROVED'),
      ),
    );

    await h.cubit.toggleLike(1);

    expect(_like(h, 1), (5, false));
    expect(h.cubit.state.event, CommunityFeedEvent.readOnlyLike);
  });

  test('read-only: told why, and nothing is sent (B12, D9)', () async {
    final before = h.cubit.state.eventVersion;

    await h.cubit.toggleLike(1, readOnly: true);

    expect(h.cubit.state.event, CommunityFeedEvent.readOnlyLike);
    expect(h.cubit.state.eventVersion, before + 1);
    expect(_like(h, 1), (5, false));
    verifyNever(() => h.setLike(any(), liked: any(named: 'liked')));
  });

  test('a second tap waits for the first answer', () async {
    final answer = Completer<Either<Failure, CommunityLikeState>>();
    when(
      () => h.setLike(1, liked: any(named: 'liked')),
    ).thenAnswer((_) => answer.future);

    final first = h.cubit.toggleLike(1);
    await h.cubit.toggleLike(1);
    answer.complete(const Right(_liked));
    await first;

    verify(() => h.setLike(1, liked: true)).called(1);
    expect(_like(h, 1), (6, true));
  });

  group('changes from elsewhere', () {
    Future<void> announce(CommunityPostChange change) async {
      h.changes.add(change);
      await Future<void>.delayed(Duration.zero);
    }

    test('a like on the post screen reaches the card', () async {
      await announce(const CommunityPostLikeChanged(2, _liked));

      expect(_like(h, 2), (6, true));
    });

    test('a fresh copy replaces the card', () async {
      await announce(CommunityPostUpdated(testPost(id: 2, commentCount: 4)));

      expect(h.cubit.state.posts.last.commentCount, 4);
    });

    test('a post gone leaves the feed; the last one leaves it empty', () async {
      await announce(const CommunityPostGone(1));
      expect([for (final p in h.cubit.state.posts) p.id], [2]);

      await announce(const CommunityPostGone(2));
      expect(h.cubit.state.status, CommunityFeedStatus.empty);
    });

    test('a post she just published goes first; one still processing '
        "doesn't join", () async {
      await announce(
        CommunityPostCreated(
          testPost(id: 9, status: CommunityPostStatus.processing),
        ),
      );
      expect([for (final p in h.cubit.state.posts) p.id], [1, 2]);

      await announce(CommunityPostCreated(testPost(id: 9)));
      expect([for (final p in h.cubit.state.posts) p.id], [9, 1, 2]);
    });

    test('an empty feed shows the post she published', () async {
      await announce(const CommunityPostGone(1));
      await announce(const CommunityPostGone(2));

      await announce(CommunityPostCreated(testPost(id: 9)));

      expect(h.cubit.state.status, CommunityFeedStatus.loaded);
      expect([for (final p in h.cubit.state.posts) p.id], [9]);
    });

    test('closing the feed stops listening', () async {
      await h.cubit.close();

      expect(h.changes.hasListener, isFalse);
    });
  });
}
