import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/data/datasources/mock/community_mock_records.dart';
import 'package:qeran/features/community/data/datasources/mock/community_mock_seed.dart';

import '../../../fixtures/community_mock_harness.dart';

void main() {
  group('feed', () {
    test('26 posts, newest first, in two pages of 20', () async {
      final ds = seededMock();

      final first = await ds.getFeed(page: 1, pageSize: 20);
      final second = await ds.getFeed(page: 2, pageSize: 20);

      expect(first.items, hasLength(20));
      expect(second.items, hasLength(6));
      expect(first.totalCount, 26);
      expect(first.totalPages, 2);
      final times = [...first.items, ...second.items].map((p) => p.createdAt!);
      expect(times.toList(), [...times]..sort((a, b) => b.compareTo(a)));
    });

    test('the board post leads: liked, 128 likes, comments and replies counted',
        () async {
      final top = (await seededMock().getFeed(page: 1, pageSize: 20)).items.first;

      expect(top.likedByMe, isTrue);
      expect(top.likeCount, 128);
      expect(top.commentCount, 27); // 23 comments + 4 replies
      expect(top.author.displayName, 'هدى العتيبي');
    });

    test('the empty mode has no posts', () async {
      final page = await seededMock(empty: true).getFeed(page: 1, pageSize: 20);

      expect(page.items, isEmpty);
      expect(page.totalPages, 0);
    });
  });

  group('comments and replies', () {
    late int postId;
    setUp(() async {
      postId = (await seededMock().getFeed(page: 1, pageSize: 20)).items.first.id;
    });

    test('comments newest first, 20 then 3', () async {
      final ds = seededMock();
      final p1 = await ds.getComments(postId, page: 1, pageSize: 20);
      final p2 = await ds.getComments(postId, page: 2, pageSize: 20);

      expect(p1.items, hasLength(20));
      expect(p2.items, hasLength(3));
      expect(p1.items.first.author.displayName, 'سارة');
      expect(p1.items.first.replyCount, 3);
    });

    test("replies oldest first, the matchmaker's among them", () async {
      final ds = seededMock();
      final sara = (await ds.getComments(postId, page: 1, pageSize: 20)).items.first;

      final replies = (await ds.getReplies(sara.id, page: 1, pageSize: 10)).items;

      expect(replies.map((r) => r.author.displayName),
          ['هدى العتيبي', 'أم خالد', 'عبدالله']);
      expect(replies.every((r) => r.parentCommentId == sara.id), isTrue);
    });

    test('flags for the viewer: own row, a matchmaker, another member', () async {
      final rows = (await seededMock().getComments(postId, page: 1, pageSize: 20))
          .items;
      final mine = rows.firstWhere((c) => c.author.id == me.id);
      final sara = rows.first;
      final huda =
          (await seededMock().getReplies(sara.id, page: 1, pageSize: 10)).items.first;

      expect((mine.isMine, mine.canDelete, mine.canBlock), (true, true, false));
      expect((sara.isMine, sara.canDelete, sara.canBlock), (false, false, true));
      expect(huda.canBlock, isFalse); // D18
    });

    test('a matchmaker viewer is never offered Block (D40)', () async {
      const mm = CommunityMockViewer(
          id: 'mock-mm-huda', displayName: 'هدى', isMatchmaker: true);
      final ds = seededMock(viewer: mm);

      final rows = (await ds.getComments(postId, page: 1, pageSize: 20)).items;

      expect(rows.any((c) => c.canBlock), isFalse);
      expect(rows.every((c) => c.canDelete), isTrue); // her own post (D3)
    });
  });

  group('likes and delete', () {
    test('likes are idempotent both ways', () async {
      final ds = seededMock();
      final id = (await ds.getFeed(page: 1, pageSize: 20)).items[1].id;
      final before = (await ds.getPost(id)).likeCount;

      await ds.setPostLike(id, liked: true);
      final twice = await ds.setPostLike(id, liked: true);
      expect((twice.likeCount, twice.likedByMe), (before + 1, true));

      await ds.setPostLike(id, liked: false);
      final again = await ds.setPostLike(id, liked: false);
      expect((again.likeCount, again.likedByMe), (before, false));
    });

    test('deleting a comment deletes its replies; the count follows', () async {
      final ds = seededMock(viewer: const CommunityMockViewer(
          id: 'mock-mm-huda', displayName: 'هدى', isMatchmaker: true));
      final post = (await ds.getFeed(page: 1, pageSize: 20)).items.first;
      final sara = (await ds.getComments(post.id, page: 1, pageSize: 20)).items.first;

      await ds.deleteComment(sara.id);

      expect((await ds.getPost(post.id)).commentCount, post.commentCount - 4);
      expect(ds.getReplies(sara.id, page: 1, pageSize: 10),
          throwsCoded('COMMENT_NOT_FOUND'));
    });

    test("a member can't delete someone else's comment", () async {
      final ds = seededMock();
      final post = (await ds.getFeed(page: 1, pageSize: 20)).items.first;
      final sara = (await ds.getComments(post.id, page: 1, pageSize: 20)).items.first;

      expect(ds.deleteComment(sara.id), throwsCoded('UNAUTHORIZED'));
    });
  });

  test('matchmakers in the seed: one with a photo, one with a long kunya', () {
    expect(CommunityMockSeed.noura['profileImageUrl'], isNotNull);
    expect(CommunityMockSeed.umm['displayName'], 'أم عبدالرحمن الشمّري');
  });
}
