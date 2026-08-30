import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/shared/data/matchmaker_notification_router.dart';

/// One compatibility-case update is pushed to THREE people — the matchmaker
/// and both members — so `audience` is the only thing separating the copy this
/// shell should act on from the two it should not.
///
/// The shell also checks the signed-in role, but that is a second line: a
/// moderator is the one running this shell, so a user-targeted copy of the
/// same event would pass the role check and open a Cases screen that answers
/// somebody else's notification.
Map<String, dynamic> _caseUpdate({String? audience}) => {
  'action': 'compatibility_case_updated',
  'caseId': '42',
  'audience': ?audience,
};

void main() {
  group('a case update addressed to the matchmaker', () {
    test('opens Cases and carries the id', () {
      final link = MatchmakerNotificationRouter.parse(
        _caseUpdate(audience: 'matchmaker'),
      );

      expect(link, isA<OpenCases>());
      expect((link as OpenCases).highlightCaseId, 42);
    });
  });

  // THE guard. Drop the audience clause and every one of these opens the
  // matchmaker's Cases tab on a notification written for a member.
  group('the same event addressed to someone else', () {
    test('an ABSENT audience is not this shell to act on', () {
      expect(
        MatchmakerNotificationRouter.parse(_caseUpdate()),
        isA<IgnoreDeepLink>(),
        reason:
            'a payload naming nobody opened the matchmaker Cases tab. Every '
            'notification predating the field arrives this way.',
      );
    });

    for (final audience in const ['user', 'member', 'sender', '']) {
      test('"$audience" is not the matchmaker', () {
        expect(
          MatchmakerNotificationRouter.parse(_caseUpdate(audience: audience)),
          isA<IgnoreDeepLink>(),
        );
      });
    }
  });

  // The spelling the server happens to use must not decide whether the
  // matchmaker can reach her own case.
  test('the matchmaker value is matched whatever its case', () {
    expect(
      MatchmakerNotificationRouter.parse(_caseUpdate(audience: 'Matchmaker')),
      isA<OpenCases>(),
    );
  });

  group('the chat route is untouched by any of this', () {
    test('a chat push still opens the conversation', () {
      final link = MatchmakerNotificationRouter.parse({
        'type': 'chat',
        'conversationId': '9',
        'senderName': 'نور',
      });

      expect(link, isA<OpenUserChat>());
      expect((link as OpenUserChat).conversationId, 9);
      expect(link.senderName, 'نور');
    });

    test('a chat push with no conversation id is ignored', () {
      expect(
        MatchmakerNotificationRouter.parse(const {'type': 'chat'}),
        isA<IgnoreDeepLink>(),
      );
    });
  });

  group('nothing to route', () {
    test('null data', () {
      expect(MatchmakerNotificationRouter.parse(null), isA<IgnoreDeepLink>());
    });

    test('empty data', () {
      expect(
        MatchmakerNotificationRouter.parse(const {}),
        isA<IgnoreDeepLink>(),
      );
    });
  });
}
