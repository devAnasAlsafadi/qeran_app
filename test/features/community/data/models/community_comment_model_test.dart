import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/data/models/community_comment_model.dart';
import 'package:qeran/features/community/data/models/community_like_state_model.dart';
import 'package:qeran/features/community/domain/entities/community_comment.dart';
import 'package:qeran/features/community/domain/entities/community_like_state.dart';

import '../../fixtures/community_fixtures.dart';

CommunityComment parse(Map<String, dynamic> json) =>
    CommunityCommentModel.fromJson(json).toEntity();

void main() {
  group('CommunityCommentModel', () {
    test('a top-level comment: every field and the member author', () {
      final c = parse(comment());

      expect(c.id, 456);
      expect(c.postId, 123);
      expect(c.parentCommentId, isNull);
      expect(c.isReply, isFalse);
      expect(c.text, 'جزاكِ الله خيراً');
      expect(c.likeCount, 12);
      expect(c.likedByMe, isTrue);
      expect(c.replyCount, 3);
      expect(c.createdAt?.toUtc(), DateTime.utc(2026, 9, 30, 8, 20));
      expect(c.isMine, isFalse);
      expect(c.canDelete, isFalse);
      expect(c.canBlock, isTrue);
      expect(c.author.displayName, 'Sara');
      expect(c.author.isMatchmaker, isFalse);
      expect(c.author.profileImageUrl, isNull);
    });

    test('a reply carries its parent and no replies of its own', () {
      final r = parse(comment(id: 457, parentCommentId: 456));

      expect(r.isReply, isTrue);
      expect(r.parentCommentId, 456);
      expect(r.replyCount, 0);
    });

    test('Block is never assumed: a missing canBlock reads false', () {
      final c = parse({...comment()}..remove('canBlock'));

      expect(c.canBlock, isFalse);
    });

    test("the author-only flag doesn't break a member's parse", () {
      final c = parse({
        ...comment(),
        'flag': {'id': 77, 'reportCount': 2, 'reasons': const []},
      });

      expect(c.id, 456);
    });

    test('a blank avatar path reads as no photo', () {
      final c = parse({
        ...comment(),
        'author': {...memberAuthor(), 'profileImageUrl': '  '},
      });

      expect(c.author.profileImageUrl, isNull);
    });
  });

  group('CommunityLikeStateModel', () {
    test('the server count and state replace the optimistic ones', () {
      final s = CommunityLikeStateModel.fromJson(
        {'likeCount': 129, 'likedByMe': true},
      ).toEntity();

      expect(s, const CommunityLikeState(likeCount: 129, likedByMe: true));
    });
  });
}
