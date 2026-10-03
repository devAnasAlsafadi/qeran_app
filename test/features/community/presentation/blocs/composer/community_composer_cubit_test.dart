import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/domain/entities/comment_submit_outcome.dart';
import 'package:qeran/features/community/presentation/blocs/composer/community_composer_state.dart';

import '../../../fixtures/community_comment_fixtures.dart';
import 'composer_cubit_harness.dart';

void main() {
  late ComposerHarness h;
  setUp(() => h = ComposerHarness());
  tearDown(() => h.dispose());

  CommunityComposerState s() => h.cubit.state;

  group('the limit, from the server (W1, S3)', () {
    test('500: the counter from 400, too long past 500', () async {
      await h.cubit.loadConfig();

      expect(s().maxLength, 500);
      expect(s().counterFrom, 400);
      expect(s().tooLong('${'a' * 500}  '), isFalse);
      expect(s().tooLong('a' * 501), isTrue);
    });

    test('unread: no counter, and the server checks (S15)', () async {
      await h.dispose();
      h = ComposerHarness(configFails: true);

      await h.cubit.loadConfig();

      expect(s().counterFrom, isNull);
      expect(s().tooLong('a' * 5000), isFalse);
    });
  });

  group('replying (D2)', () {
    test('a comment\'s Reply: the strip, and the field takes the focus', () {
      h.cubit.replyTo(testComment(id: 10));

      expect(s().replyTo?.id, 10);
      expect(s().event, CommunityComposerEvent.focus);

      h.cubit.cancelReply();
      expect(s().replyTo, isNull);
    });

    test('sent: under that comment, then back to writing a comment', () async {
      h.cubit.replyTo(testComment(id: 10));

      await h.cubit.submit(' شكراً لكِ ');

      expect(h.sent, [('شكراً لكِ', 10)]);
      expect(s().replyTo, isNull);
    });
  });

  group('nothing goes', () {
    setUp(() => h.cubit.loadConfig());

    test('empty, or only spaces', () async {
      await h.cubit.submit('   ');

      expect(h.sent, isEmpty);
    });

    test('past the limit (D4)', () async {
      await h.cubit.submit('a' * 501);

      expect(h.sent, isEmpty);
    });
  });

  test('posted, or failed as a row: nothing comes back to the field', () async {
    for (final answer in [null, const CommentPostGone()]) {
      h.answer = answer;
      final before = s().eventVersion;

      await h.cubit.submit('سؤال');

      expect((s().restore, s().eventVersion), (null, before));
    }
  });

  group('refused: the text comes back, and why', () {
    test('the filter: the banner; answering a comment, still answering it '
        '(D8)', () async {
      h.cubit.replyTo(testComment(id: 10));
      h.answer = const CommentFiltered();

      await h.cubit.submit('راسلني على الواتس');

      expect(s().filtered, isTrue);
      expect(s().restore, 'راسلني على الواتس');
      expect(s().replyTo?.id, 10);
      expect(s().event, CommunityComposerEvent.filtered);
    });

    test('the next send takes the banner away', () async {
      h.answer = const CommentFiltered();
      await h.cubit.submit('أ');
      h.answer = null;

      await h.cubit.submit('ب');

      expect(s().filtered, isFalse);
    });

    final gates = {
      const CommentNameRequired(): CommunityComposerEvent.openNameGate,
      const CommentGuidelinesRequired(): CommunityComposerEvent.openGuidelines,
      const CommentNotApproved(): CommunityComposerEvent.notApproved,
    };
    for (final MapEntry(key: outcome, value: event) in gates.entries) {
      test('${outcome.runtimeType}: ${event.name} (S5)', () async {
        h.answer = outcome;

        await h.cubit.submit('سؤال');

        expect((s().restore, s().event), ('سؤال', event));
      });
    }

    test('the comment it answered is gone: back to a comment (S9)', () async {
      h.cubit.replyTo(testComment(id: 10));
      h.answer = const CommentParentGone();

      await h.cubit.submit('رد');

      expect(s().replyTo, isNull);
      expect(
        (s().restore, s().event),
        ('رد', CommunityComposerEvent.contentGone),
      );
    });
  });

  group('rate limited (D9)', () {
    test('rests for the server\'s wait, then sends again', () async {
      h.answer = const CommentRateLimited(
        retryAfter: Duration(milliseconds: 20),
      );

      await h.cubit.submit('سؤال');
      expect(s().coolingDown, isTrue);
      expect(
        (s().restore, s().event),
        ('سؤال', CommunityComposerEvent.rateLimited),
      );

      h.answer = null;
      await h.cubit.submit('سؤال');
      expect(h.sent, hasLength(1));

      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(s().coolingDown, isFalse);
      await h.cubit.submit('سؤال');
      expect(h.sent, hasLength(2));
    });

    test('a bare 429 says no wait: the default rest', () async {
      await h.dispose();
      h = ComposerHarness(cooldown: const Duration(milliseconds: 20));
      h.answer = const CommentRateLimited();

      await h.cubit.submit('سؤال');
      expect(s().coolingDown, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(s().coolingDown, isFalse);
    });
  });

  test(
    'a failed row\'s retry: the same text, still answering its comment',
    () async {
      h.answer = const CommentFiltered();

      await h.cubit.retry(-3, 'رد', parent: testComment(id: 10));

      expect(h.retried, [-3]);
      expect((s().restore, s().replyTo?.id), ('رد', 10));
    },
  );
}
