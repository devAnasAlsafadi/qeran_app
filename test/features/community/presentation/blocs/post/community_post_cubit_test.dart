import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/community_like_state.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/domain/entities/community_post_change.dart';
import 'package:qeran/features/community/presentation/blocs/post/community_post_state.dart';

import '../../../fixtures/community_post_fixtures.dart';
import 'post_cubit_harness.dart';

const _liked = CommunityLikeState(likeCount: 6, likedByMe: true);

void main() {
  group('opened from the feed, with its copy', () {
    late PostHarness h;
    setUp(() => h = PostHarness(post: testPost(likeCount: 5)));
    tearDown(() => h.dispose());

    test('shows at once, then the fresh copy (C1)', () async {
      expect(h.post.likeCount, 5);
      h.readAnswers(Right(testPost(likeCount: 5, commentCount: 3)));

      await h.cubit.load();

      expect(h.post.commentCount, 3);
    });

    test('a fresh copy that can\'t be read: the copy stays', () async {
      h.readAnswers(const Left(OfflineFailure()));

      await h.cubit.load();

      expect(h.post, testPost(likeCount: 5));
    });

    test('gone on the server: no longer available (C7)', () async {
      h.readAnswers(const Left(postNotFound));

      await h.cubit.load();

      expect(h.cubit.state, const CommunityPostRemoved());
    });
  });

  group('opened without a copy (a notification)', () {
    late PostHarness h;
    setUp(() => h = PostHarness());
    tearDown(() => h.dispose());

    test('loading, then the post', () async {
      expect(h.cubit.state, const CommunityPostLoading());
      h.readAnswers(Right(testPost()));

      await h.cubit.load();

      expect(h.post, testPost());
    });

    test('can\'t be read: the error, and its retry reads again', () async {
      h.readAnswers(const Left(OfflineFailure()));
      await h.cubit.load();
      expect(h.cubit.state, const CommunityPostFailed());

      h.readAnswers(Right(testPost()));
      await h.cubit.load();
      expect(h.post, testPost());
    });

    test('gone: no longer available, not an error', () async {
      h.readAnswers(const Left(postNotFound));

      await h.cubit.load();

      expect(h.cubit.state, const CommunityPostRemoved());
    });
  });

  group('changes from elsewhere', () {
    late PostHarness h;
    setUp(() => h = PostHarness(post: testPost(likeCount: 5)));
    tearDown(() => h.dispose());

    test('a like and a fresh copy apply to this post only', () async {
      await h.announce(const CommunityPostLikeChanged(2, _liked));
      expect(h.post.likeCount, 5);

      await h.announce(const CommunityPostLikeChanged(1, _liked));
      expect(h.post.likeCount, 6);

      await h.announce(CommunityPostUpdated(testPost(commentCount: 7)));
      expect(h.post.commentCount, 7);
    });

    test(
      'gone — the comments\' read found it so: no longer available',
      () async {
        await h.announce(const CommunityPostGone(2));
        expect(h.cubit.state, isA<CommunityPostReady>());

        await h.announce(const CommunityPostGone(1));
        expect(h.cubit.state, const CommunityPostRemoved());

        await h.announce(CommunityPostUpdated(testPost()));
        expect(h.cubit.state, const CommunityPostRemoved());
      },
    );

    test('closing the screen stops listening', () async {
      await h.cubit.close();

      expect(h.changes.hasListener, isFalse);
    });
  });

  test('a copy keeps the last message told when it changes', () {
    final told = CommunityPostReady(
      testPost(),
    ).withEvent(CommunityPostEvent.likeFailed);
    final CommunityPost fresh = testPost(commentCount: 2);

    final next = told.withPost(fresh);

    expect((next.event, next.eventVersion), (CommunityPostEvent.likeFailed, 1));
  });
}
