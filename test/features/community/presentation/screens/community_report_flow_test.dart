import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/presentation/widgets/comments/comment_row.dart';
import 'package:qeran/features/community/presentation/widgets/menus/community_menu_button.dart';
import 'package:qeran/features/community/presentation/widgets/post_card/community_post_card.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';
import 'package:qeran/features/report/di/report_injection.dart';
import 'package:qeran/features/report/domain/entities/report_reason.dart';
import 'package:qeran/features/report/domain/entities/report_target.dart';
import 'package:qeran/features/report/domain/repositories/content_reporter.dart';
import 'package:qeran/features/report/presentation/blocs/report_cubit.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../fixtures/community_comment_fixtures.dart';
import '../../fixtures/community_post_fixtures.dart';
import '../blocs/comments/comments_cubit_harness.dart';
import '../blocs/feed/feed_cubit_harness.dart';
import '../blocs/post/post_cubit_harness.dart';
import 'feed_screen_rig.dart';
import 'post_screen_rig.dart';

class _Reporter implements ContentReporter {
  final reported = <ContentReportTarget>[];

  @override
  Future<Either<Failure, void>> report(
    ContentReportTarget target, {
    required ReportReason reason,
    String? note,
  }) async {
    reported.add(target);
    return const Right(null);
  }
}

/// Reporting from the post screen's ⋮ (E1–E6): the post, someone's comment,
/// a reply — each named in the menu and the sheet, each sent through
/// Community (Q3).
void main() {
  late PostHarness post;
  late CommentsHarness comments;
  late _Reporter community;

  setUpAll(initShippedStrings);
  setUp(() async {
    community = _Reporter();
    sl.registerSingleton<ContentReporter>(community);
    sl.registerFactoryParam<ReportCubit, ReportTarget, void>(
      (target, _) => ReportCubit(send: reportCallFor(target)),
    );
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

  testWidgets('my own comment has nothing to report', (tester) async {
    await pumpPostScreen(tester, post, comments);

    expect(find.byType(CommentRow), findsNWidgets(3));
    expect(menuOf(row(11)), findsNothing);
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
