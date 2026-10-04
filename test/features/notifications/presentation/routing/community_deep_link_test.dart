import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/domain/entities/community_landing.dart';
import 'package:qeran/features/notifications/domain/entities/notification_item.dart';
import 'package:qeran/features/notifications/domain/entities/notification_type.dart';
import 'package:qeran/features/notifications/presentation/routing/notification_deep_link.dart';

/// A Community notification opens its post at the comment and reply it is
/// about (contract §7.2, H1, C8). A push carries its ids as strings; the
/// inbox's decoded `data` may carry numbers.
void main() {
  const atReply = OpenCommunityPost(
    postId: 5,
    landing: CommunityLanding(commentId: 40, replyId: 41),
  );

  test('"New reply to your comment", pushed: the post, at the reply', () {
    expect(
      NotificationDeepLinkRouter.resolveData({
        'type': 'Community',
        'screen': 'community_post',
        'action': 'community_reply',
        'postId': '5',
        'commentId': '40',
        'replyId': '41',
        'audience': 'member',
      }),
      atReply,
    );
  });

  test('the same, from the inbox with numbers', () {
    final row = NotificationItem(
      id: 1,
      titleAr: 'ردّ جديد على تعليقك',
      titleEn: 'New reply to your comment',
      bodyAr: '',
      bodyEn: '',
      type: NotificationType.community,
      data: const {
        'screen': 'community_post',
        'postId': 5,
        'commentId': 40,
        'replyId': 41,
      },
      createdAt: null,
    );

    expect(NotificationDeepLinkRouter.resolve(row), atReply);
  });

  test('a comment without a reply: the post, at the comment', () {
    expect(
      NotificationDeepLinkRouter.resolveData({
        'screen': 'community_post',
        'postId': '5',
        'commentId': '40',
      }),
      const OpenCommunityPost(
        postId: 5,
        landing: CommunityLanding(commentId: 40),
      ),
    );
  });

  test('no comment: the post, from its top', () {
    expect(
      NotificationDeepLinkRouter.resolveData({
        'screen': 'community_post',
        'postId': '5',
      }),
      const OpenCommunityPost(postId: 5),
    );
  });

  test('no screen: the Community type still opens the post', () {
    expect(
      NotificationDeepLinkRouter.resolveData({
        'type': 'Community',
        'postId': '5',
        'commentId': '40',
        'replyId': '41',
      }),
      atReply,
    );
  });

  test('no post, or one that isn\'t a number: nowhere (never throws)', () {
    for (final postId in [null, '', 'abc', '5.5']) {
      expect(
        NotificationDeepLinkRouter.resolveData({
          'screen': 'community_post',
          'postId': ?postId,
          'commentId': '40',
        }),
        isA<NoDeepLink>(),
        reason: 'postId: $postId',
      );
    }
  });
}
