import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/presentation/widgets/menus/community_menu_button.dart';
import 'package:qeran/features/community/presentation/widgets/post_card/community_post_card.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';
import 'package:qeran/features/report/domain/entities/report_target.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../fixtures/community_comment_fixtures.dart';
import '../../fixtures/community_post_fixtures.dart';
import '../blocs/comments/comments_cubit_harness.dart';
import '../blocs/feed/feed_cubit_harness.dart';
import '../blocs/post/post_cubit_harness.dart';
import 'feed_screen_rig.dart';
import 'post_screen_rig.dart';
import 'report_rig.dart';

/// Reporting from the post screen's ⋮ (E1–E6): the post, someone's comment,
/// a reply — each named in the menu and the sheet, each sent through
/// Community (Q3).
void main() {
  late PostHarness post;
  late CommentsHarness comments;
  late FakeReporter community;

  setUpAll(initShippedStrings);
  setUp(() async {
    community = FakeReporter();
    registerReporting(community);
    post = PostHarness(post: testPost(commentCount: 3));
    comments = CommentsHarness();
    comments.page(1, [
      testComment(id: 10, replyCount: 1),
      testComment(id: 11, isMine: true, canDelete: true),
    ]);
    comments.replies(10, 1, [testReply(id: 100, author: sara)]);
    await comments.cubit.load();
    await comments.cubit.showReplies(10);
  });
  tearDown(() async {
    await sl.reset();
    await post.dispose();
    await comments.dispose();
  });

  Finder menuOf(Finder holder) =>
      find.descendant(of: holder, matching: find.byType(CommunityMenuButton));

  Finder row(int id) => find.byKey(ValueKey('comment-$id'));

  Future<void> reportThrough(
    WidgetTester tester,
    Finder menu,
    String row,
    String reason,
    String send,
  ) async {
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text(row));
    await tester.pumpAndSettle();
    await tester.tap(find.text(reason));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(QeranButton, send));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testWidgets('the post, a comment and a reply, each by name [en]', (
    tester,
  ) async {
    await pumpPostScreen(tester, post, comments);

    await reportThrough(
      tester,
      menuOf(find.byType(CommunityPostCard)),
      'Report post',
      'Spam or advertising',
      'Submit report',
    );
    await reportThrough(
      tester,
      menuOf(row(10)),
      'Report comment',
      'Abuse or bullying',
      'Submit report',
    );
    await reportThrough(
      tester,
      menuOf(row(100)),
      'Report reply',
      'Something else',
      'Submit report',
    );

    expect(community.reported, const [
      ContentReportTarget(ReportContentKind.post, 1),
      ContentReportTarget(ReportContentKind.comment, 10),
      ContentReportTarget(ReportContentKind.reply, 100),
    ]);
  });

  for (final (kind, id, staying) in [
    ('comment', 10, [11]),
    ('reply', 100, [10, 11]),
  ]) {
    testWidgets('E7: a $kind found gone — its row leaves, as on a delete', (
      tester,
    ) async {
      community.answer = const Left(
        CodedServerFailure(message: 'x', errorCode: 'TARGET_CONTENT_NOT_FOUND'),
      );
      await pumpPostScreen(tester, post, comments);

      await reportThrough(
        tester,
        menuOf(row(id)),
        'Report $kind',
        'Something else',
        'Submit report',
      );

      expect(row(id), findsNothing);
      for (final other in staying) {
        expect(row(other), findsOneWidget);
      }
      verify(() => comments.getPost(1)).called(1);
    });
  }

  testWidgets('the menu and the sheet name the comment [ar]', (tester) async {
    await pumpPostScreen(tester, post, comments, locale: const Locale('ar'));

    await tester.tap(menuOf(row(10)));
    await tester.pumpAndSettle();
    expect(find.text('الإبلاغ عن التعليق'), findsOneWidget);
    await tester.tap(find.text('الإبلاغ عن التعليق'));
    await tester.pumpAndSettle();

    expect(find.text('الإبلاغ عن التعليق'), findsOneWidget);
    expect(find.text('مشاركة معلومات تواصل'), findsOneWidget);
  });

  testWidgets('my own comment offers Delete, never Report (E3)', (
    tester,
  ) async {
    await pumpPostScreen(tester, post, comments);

    await tester.tap(menuOf(row(11)));
    await tester.pumpAndSettle();

    expect(find.text('Delete comment'), findsOneWidget);
    expect(find.text('Report comment'), findsNothing);
  });

  testWidgets('a feed card has the same ⋮ (E1), even for a member who '
      'reads only — reporting is never gated', (tester) async {
    final feed = FeedHarness();
    addTearDown(feed.dispose);
    feed.page(1, [testPost(id: 2)]);
    await feed.cubit.load();
    await pumpFeed(tester, feed, gate: ProfileStatus.pendingReview);

    await reportThrough(
      tester,
      menuOf(find.byType(CommunityPostCard)),
      'Report post',
      'Inappropriate content',
      'Submit report',
    );

    expect(community.reported, const [
      ContentReportTarget(ReportContentKind.post, 2),
    ]);
  });
}
