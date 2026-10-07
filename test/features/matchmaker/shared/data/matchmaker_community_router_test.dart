import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/domain/entities/community_landing.dart';
import 'package:qeran/features/matchmaker/shared/data/matchmaker_notification_router.dart';
import 'package:qeran/features/notifications/domain/entities/community_post_target.dart';

/// Contract §7.2's three Community notifications, as a push carries them:
/// ids as strings; for a reported reply, `commentId` is its parent.
const _ids = {
  'community_comment': {'postId': '5', 'commentId': '10'},
  'community_reply': {'postId': '5', 'commentId': '10', 'replyId': '100'},
  'community_report': {
    'postId': '5',
    'commentId': '10',
    'replyId': '100',
    'flagId': '7',
  },
};

/// Where each lands (C8): the comment, the reply, the reported reply.
const _landings = {
  'community_comment': CommunityLanding(commentId: 10),
  'community_reply': CommunityLanding(commentId: 10, replyId: 100),
  'community_report': CommunityLanding(commentId: 10, replyId: 100),
};

Map<String, dynamic> _push(String action, {String? audience}) => {
  'type': 'Community',
  'screen': 'community_post',
  'action': action,
  ..._ids[action]!,
  'audience': ?audience,
};

MatchmakerDeepLink _parse(Map<String, dynamic> data) =>
    MatchmakerNotificationRouter.parse(data);

/// Her Community notifications: each action × audience. A reply to a
/// member's comment reaches the member with the same shape, so only
/// `audience: matchmaker` is hers to open.
void main() {
  for (final action in _ids.keys) {
    group(action, () {
      test('addressed to her: the post at its item', () {
        expect(
          _parse(_push(action, audience: 'matchmaker')),
          OpenPost(CommunityPostTarget(postId: 5, landing: _landings[action])),
        );
        expect(_parse(_push(action, audience: 'Matchmaker')), isA<OpenPost>());
      });

      for (final audience in [null, 'member', 'user', '']) {
        test('addressed to ${audience ?? 'nobody'}: nothing', () {
          expect(
            _parse(_push(action, audience: audience)),
            isA<IgnoreDeepLink>(),
          );
        });
      }
    });
  }

  test('a report on a comment lands on the comment; its flag id plays no '
      'part (D36: the post, never «البلاغات»)', () {
    final link = _parse({
      ..._push('community_report', audience: 'matchmaker'),
      'replyId': null,
    });
    expect(
      link,
      const OpenPost(
        CommunityPostTarget(
          postId: 5,
          landing: CommunityLanding(commentId: 10),
        ),
      ),
    );
  });

  test('from her inbox: numbers for ids, and the type alone', () {
    final link = _parse({
      'type': 'Community',
      'action': 'community_comment',
      'postId': 5,
      'commentId': 10,
      'audience': 'matchmaker',
    });
    expect(
      link,
      const OpenPost(
        CommunityPostTarget(
          postId: 5,
          landing: CommunityLanding(commentId: 10),
        ),
      ),
    );
  });

  test('a post and no comment: the post from its top', () {
    expect(
      _parse(const {
        'screen': 'community_post',
        'postId': '5',
        'audience': 'matchmaker',
      }),
      const OpenPost(CommunityPostTarget(postId: 5)),
    );
  });

  test('no post, or one that is not a number: nothing', () {
    for (final postId in [null, '', 'five']) {
      expect(
        _parse({
          ..._push('community_comment', audience: 'matchmaker'),
          'postId': postId,
        }),
        isA<IgnoreDeepLink>(),
      );
    }
  });
}
