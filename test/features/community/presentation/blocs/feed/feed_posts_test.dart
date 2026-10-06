import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/domain/entities/community_like_state.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/presentation/blocs/feed/feed_posts.dart';

import '../../../fixtures/community_post_fixtures.dart';

List<int> _ids(List posts) => [for (final post in posts) post.id as int];

void main() {
  test('a page adds only the posts the list hasn\'t got', () {
    final list = [testPost(id: 9), testPost(id: 8)];
    final page = [testPost(id: 8), testPost(id: 7)];

    expect(_ids(appendNewPosts(list, page)), [9, 8, 7]);
  });

  test('a first page keeps each post once', () {
    expect(_ids(distinctPosts([testPost(id: 2), testPost(id: 2)])), [2]);
  });

  test('replace, like and remove touch only their post', () {
    final list = [testPost(id: 2), testPost(id: 1)];

    final replaced = replacePost(list, testPost(id: 1, commentCount: 5));
    expect([replaced[0].commentCount, replaced[1].commentCount], [0, 5]);

    final liked = withLike(
      list,
      2,
      const CommunityLikeState(likeCount: 7, likedByMe: true),
    );
    expect([liked[0].likeCount, liked[0].likedByMe], [7, true]);
    expect(liked[1], list[1]);

    expect(_ids(withoutPost(list, 2)), [1]);
  });

  test('a post she just published goes first, or replaces its copy; one '
      'still processing stays out (S15)', () {
    final list = [testPost(id: 2), testPost(id: 1)];

    expect(_ids(withCreatedPost(list, testPost(id: 3))!), [3, 2, 1]);
    final again = withCreatedPost(list, testPost(id: 2, commentCount: 1))!;
    expect(_ids(again), [2, 1]);
    expect(again.first.commentCount, 1);
    final processing = testPost(id: 3, status: CommunityPostStatus.processing);
    expect(withCreatedPost(list, processing), isNull);
  });

  test('the tap flips the like and moves the count, never below zero', () {
    expect(
      flippedLike(testPost(likeCount: 3)),
      const CommunityLikeState(likeCount: 4, likedByMe: true),
    );
    expect(
      flippedLike(testPost(likeCount: 3, likedByMe: true)),
      const CommunityLikeState(likeCount: 2, likedByMe: false),
    );
    expect(
      flippedLike(testPost(likeCount: 0, likedByMe: true)),
      const CommunityLikeState(likeCount: 0, likedByMe: false),
    );
  });
}
