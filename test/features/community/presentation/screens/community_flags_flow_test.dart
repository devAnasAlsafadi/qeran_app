import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/features/community/domain/entities/community_flag.dart';
import 'package:qeran/features/community/domain/entities/community_viewer.dart';
import 'package:qeran/features/community/presentation/widgets/comments/comment_flag_panel.dart';
import 'package:qeran/features/community/presentation/widgets/menus/community_menu_button.dart';
import 'package:qeran/features/report/domain/entities/report_reason.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../fixtures/community_comment_fixtures.dart';
import '../../fixtures/community_post_fixtures.dart';
import '../blocs/comments/comments_cubit_harness.dart';
import '../blocs/post/post_cubit_harness.dart';
import 'post_screen_rig.dart';

const _ar = Locale('ar');
const _en = Locale('en');

final _copy = {
  _ar: (
    line: 'تم الإبلاغ · بلاغان · إساءة أو تنمّر',
    replyLine: 'تم الإبلاغ · بلاغ واحد · مشاركة معلومات تواصل',
    keepComment: 'إبقاء التعليق',
    keepReply: 'إبقاء الرد',
    delete: 'حذف',
    kept: 'أُبقي التعليق وأُزيلت علامة البلاغ.',
    keptReply: 'أُبقي الرد وأُزيلت علامة البلاغ.',
    askTitle: 'حذف التعليق؟',
    askBody: 'سيُحذف هذا التعليق وكل الردود عليه نهائياً ولا يمكن استعادته.',
    deleted: 'تم حذف التعليق.',
    like: 'إعجاب',
  ),
  _en: (
    line: 'Reported · 2 reports · Abuse or bullying',
    replyLine: 'Reported · 1 report · Sharing contact details',
    keepComment: 'Keep',
    keepReply: 'Keep',
    delete: 'Delete',
    kept: 'Comment kept and the report flag removed.',
    keptReply: 'Reply kept and the report flag removed.',
    askTitle: 'Delete comment?',
    askBody: 'This comment and all its replies will be deleted permanently.',
    deleted: 'Comment deleted.',
    like: 'Like',
  ),
};

/// Her post screen with reports on it (E1–E6, Q11, D40).
void main() {
  late PostHarness post;
  late CommentsHarness comments;

  setUpAll(initShippedStrings);
  setUp(() async {
    post = PostHarness(post: testPost(commentCount: 3));
    comments = CommentsHarness();
    comments.page(1, [
      testComment(
        id: 10,
        author: fahad,
        replyCount: 1,
        canDelete: true,
        flag: const CommunityFlag(
          id: 77,
          reportCount: 2,
          topReason: ReportReason.harassment,
        ),
      ),
      testComment(id: 11, canDelete: true),
    ]);
    comments.replies(10, 1, [
      testReply(
        id: 100,
        author: sara,
        canDelete: true,
        flag: const CommunityFlag(
          id: 78,
          reportCount: 1,
          topReason: ReportReason.contactDetails,
        ),
      ),
    ]);
    await comments.cubit.load();
    await comments.cubit.showReplies(10);
    when(
      () => comments.dismissFlag(any()),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => comments.delete(any()),
    ).thenAnswer((_) async => const Right(unit));
  });
  tearDown(() async {
    await post.dispose();
    await comments.dispose();
  });

  Future<void> pump(WidgetTester tester, Locale locale) => pumpPostScreen(
    tester,
    post,
    comments,
    locale: locale,
    viewer: CommunityViewer.matchmaker,
  );

  Finder row(int id) => find.byKey(ValueKey('comment-$id'));
  Finder inRow(int id, Finder finder) =>
      find.descendant(of: row(id), matching: finder);

  for (final locale in [_ar, _en]) {
    final t = _copy[locale]!;

    testWidgets('E1, E2 [${locale.languageCode}]: «${t.line}» with '
        '«${t.keepComment}» and «${t.delete}», no Like or Reply; the reply\'s '
        'with «${t.keepReply}»; ⋮ stays', (tester) async {
      await pump(tester, locale);

      expect(inRow(10, find.text(t.line)), findsOneWidget);
      expect(inRow(10, find.text(t.keepComment)), findsOneWidget);
      expect(inRow(10, find.text(t.delete)), findsOneWidget);
      expect(inRow(10, find.text(t.like)), findsNothing);
      expect(inRow(10, find.byType(CommunityMenuButton)), findsOneWidget);
      expect(inRow(100, find.text(t.replyLine)), findsOneWidget);
      expect(inRow(100, find.text(t.keepReply)), findsOneWidget);
      expect(inRow(11, find.text(t.like)), findsOneWidget);
      expect(inRow(11, find.byType(CommentFlagActions)), findsNothing);
    });

    testWidgets('E3, Q11 [${locale.languageCode}]: Keep — the flag goes, '
        'Like comes back, «${t.kept}»; the reply\'s «${t.keptReply}»', (
      tester,
    ) async {
      await pump(tester, locale);

      await tester.tap(inRow(10, find.text(t.keepComment)));
      await tester.pumpAndSettle();
      expect(find.text(t.kept), findsOneWidget);
      expect(inRow(10, find.text(t.line)), findsNothing);
      expect(inRow(10, find.text(t.like)), findsOneWidget);
      verify(() => comments.dismissFlag(77)).called(1);

      await tester.tap(inRow(100, find.text(t.keepReply)));
      await tester.pumpAndSettle();
      expect(find.text(t.keptReply), findsOneWidget);
      expect(comments.flagsCleared, 2);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('E4, E6 [${locale.languageCode}]: «${t.delete}» asks in her '
        'words for an item that isn\'t hers, then «${t.deleted}»', (
      tester,
    ) async {
      await pump(tester, locale);

      await tester.tap(inRow(10, find.text(t.delete)));
      await tester.pumpAndSettle();
      expect(find.text(t.askTitle), findsOneWidget);
      expect(find.text(t.askBody), findsOneWidget);
      await tester.tap(find.text(t.delete).last);
      await tester.pumpAndSettle();

      expect(row(10), findsNothing);
      expect(find.text(t.deleted), findsOneWidget);
      expect(comments.flagsCleared, 1);
      await tester.pump(const Duration(seconds: 5));
    });
  }

  testWidgets('D40: a reported row\'s ⋮ never offers her Block', (
    tester,
  ) async {
    await pump(tester, _en);

    await tester.tap(inRow(10, find.byType(CommunityMenuButton)));
    await tester.pumpAndSettle();

    expect(find.text('Block'), findsNothing);
    expect(find.textContaining('Report'), findsWidgets);
  });
}
