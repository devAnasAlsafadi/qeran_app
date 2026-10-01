import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/community/data/datasources/mock/community_mock_datasource.dart';

import '../../../fixtures/community_mock_harness.dart';

Future<int> firstPostId(CommunityMockDataSource ds) async =>
    (await ds.getFeed(page: 1, pageSize: 20)).items.first.id;

void main() {
  group('gates, in the server order', () {
    test('guidelines first, then accepting the current version unlocks',
        () async {
      final ds = seededMock(accepted: false);
      final post = await firstPostId(ds);

      await expectLater(ds.createComment(post, 'شكراً'),
          throwsCoded('COMMUNITY_GUIDELINES_NOT_ACCEPTED'));
      await expectLater(ds.acceptGuidelines(99), throwsCoded('VALIDATION_ERROR'));

      final version = (await ds.getGuidelines()).version;
      await ds.acceptGuidelines(version);
      final sent = await ds.createComment(post, '  شكراً  ');

      expect(sent.text, 'شكراً');
      expect(sent.isMine, isTrue);
      expect(ds.guidelinesAccepted, isTrue);
    });

    test('an injected fault answers first — the profile-only gates', () async {
      final ds = seededMock();
      final post = await firstPostId(ds);

      ds.failNextCallWith('DISPLAY_NAME_REQUIRED');
      await expectLater(
          ds.createComment(post, 'x'), throwsCoded('DISPLAY_NAME_REQUIRED'));
      expect((await ds.createComment(post, 'x')).text, 'x');
    });

    test('empty, blank and over 500 characters are VALIDATION_ERROR', () async {
      final ds = seededMock();
      final post = await firstPostId(ds);

      for (final text in ['', '   ', 'ا' * 501]) {
        await expectLater(
            ds.createComment(post, text), throwsCoded('VALIDATION_ERROR'));
      }
      expect((await ds.createComment(post, 'ا' * 500)).text.length, 500);
    });

    test('a reply to a reply is VALIDATION_ERROR (one level, D2)', () async {
      final ds = seededMock();
      final post = await firstPostId(ds);
      final comment = await ds.createComment(post, 'سؤال');
      final reply = await ds.createReply(comment.id, 'جواب');

      expect(reply.parentCommentId, comment.id);
      await expectLater(
          ds.createReply(reply.id, 'رد'), throwsCoded('VALIDATION_ERROR'));
    });

    test('the sixth in a minute is RATE_LIMITED; a minute later it passes',
        () async {
      final clock = TestClock();
      final ds = seededMock(clock: clock);
      final post = await firstPostId(ds);

      for (var i = 0; i < 5; i++) {
        await ds.createComment(post, 'تعليق $i');
      }
      await expectLater(
          ds.createComment(post, 'سادس'), throwsCoded('RATE_LIMITED'));

      clock.advance(const Duration(minutes: 1));
      expect((await ds.createComment(post, 'بعد دقيقة')).text, 'بعد دقيقة');
    });

    test('contact details are CONTENT_NOT_ALLOWED; the text is never stored',
        () async {
      final clock = TestClock();
      final ds = seededMock(clock: clock);
      final post = await firstPostId(ds);
      final before = (await ds.getPost(post)).commentCount;

      for (final text in [
        'رقمي ٠٥٩ ١٢٣ ٤٥٦٧',
        'call 0 5 9 1 2 3 4 5 6 7',
        'a@b.co',
        'www.example.com',
        'تابعني @handle',
        'كلمني واتس',
      ]) {
        clock.advance(const Duration(minutes: 1));
        await expectLater(
            ds.createComment(post, text), throwsCoded('CONTENT_NOT_ALLOWED'));
      }
      expect((await ds.getPost(post)).commentCount, before);
    });

    test('ordinary numbers and words pass the filter', () async {
      final ds = seededMock();
      final post = await firstPostId(ds);

      expect((await ds.createComment(post, 'عمري 25 وعندي سؤال')).id, isPositive);
    });
  });

  group('errors as HttpConsumer throws them', () {
    test('unknown ids: POST_NOT_FOUND and COMMENT_NOT_FOUND', () async {
      final ds = seededMock();

      await expectLater(ds.getPost(1), throwsCoded('POST_NOT_FOUND'));
      await expectLater(ds.createComment(1, 'x'), throwsCoded('POST_NOT_FOUND'));
      await expectLater(ds.getComment(1), throwsCoded('COMMENT_NOT_FOUND'));
      await expectLater(ds.createReply(1, 'x'), throwsCoded('COMMENT_NOT_FOUND'));
    });

    test('offline → OfflineException, before anything else', () async {
      final net = FakeConnectivity()..online = false;

      await expectLater(seededMock(connectivity: net).getFeed(page: 1, pageSize: 20),
          throwsA(isA<OfflineException>()));
    });

    test('the errors mode fails every call', () async {
      await expectLater(
        seededMock(failEverything: true).getConfig(),
        throwsA(isA<ServerException>()),
      );
    });
  });

  test("config and guidelines are Tariq's values and the board's text", () async {
    final ds = seededMock();

    final config = await ds.getConfig();
    final guidelines = await ds.getGuidelines();

    expect(config.commentMaxLength, 500);
    expect(config.maxVideoDurationSeconds, 60);
    expect(guidelines.sections, hasLength(5));
    expect(guidelines.sections.last.bodyAr, contains('من قائمة الخيارات'));
    expect(guidelines.sections.last.bodyEn, contains('from the options menu'));
  });
}
