import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/community/domain/entities/community_landing.dart';
import 'package:qeran/features/community/presentation/screens/community_post_page.dart';
import 'package:qeran/features/matchmaker/community/presentation/screens/community_reports_page.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../../community/fixtures/community_comment_fixtures.dart';
import '../../../community/fixtures/community_post_fixtures.dart';
import '../../../community/presentation/blocs/comments/comments_cubit_harness.dart';
import '../../../community/presentation/blocs/post/post_cubit_harness.dart';
import '../../../community/presentation/screens/post_screen_rig.dart';
import '../reports_rig.dart';

final _copy = {
  'ar': (
    title: 'البلاغات',
    intro:
        'بلاغات على تعليقات وردود في منشوراتك. أبقي العنصر أو احذفيه، وفي '
        'الحالتين تُزال العلامة.',
    line: 'تم الإبلاغ · بلاغان · إساءة أو تنمّر',
    kind: '· تعليق',
    replyKind: '· رد',
    on: 'على: الاستخارة والاستشارة',
    keep: 'إبقاء',
    delete: 'حذف',
    kept: 'أُبقي التعليق وأُزيلت علامة البلاغ.',
    askBody: 'سيُحذف هذا الرد نهائياً ولا يمكن استعادته.',
    deletedReply: 'تم حذف الرد.',
    emptyTitle: 'لا توجد بلاغات بانتظارك',
    emptyBody: 'ستظهر هنا البلاغات على التعليقات والردود في منشوراتك.',
    error: 'تعذّر تحميل البلاغات',
    retry: 'حاولي مرة أخرى',
  ),
  'en': (
    title: 'Reports',
    intro:
        'Reports on comments and replies in your posts. Keep the item or '
        'delete it; either way the flag is cleared.',
    line: 'Reported · 2 reports · Abuse or bullying',
    kind: '· Comment',
    replyKind: '· Reply',
    on: 'On: الاستخارة والاستشارة',
    keep: 'Keep',
    delete: 'Delete',
    kept: 'Comment kept and the report flag removed.',
    askBody: 'This reply will be deleted permanently.',
    deletedReply: 'Reply deleted.',
    emptyTitle: 'No reports waiting for you',
    emptyBody:
        'Reports on comments and replies in your posts will appear here.',
    error: 'Couldn’t load reports',
    retry: 'Try again',
  ),
};

/// «البلاغات» as she sees it (E7–E10, D36, S17).
void main() {
  late ReportsHarness h;
  setUpAll(initShippedStrings);
  setUp(() => h = ReportsHarness());
  tearDown(sl.reset);

  Future<void> pump(WidgetTester tester, String language) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1400);
    addTearDown(tester.view.reset);
    addTearDown(AppSnackBar.debugReset);
    await pumpShippedStrings(
      tester,
      Locale(language),
      settle: false,
      builder: (_, navigator) => postScreenLayers(navigator!),
      child: BlocProvider(
        create: (_) => h.newCubit()..load(),
        child: const CommunityReportsScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final MapEntry(key: language, value: t) in _copy.entries) {
    testWidgets('E7 [$language]: «${t.title}», the intro, and a card per '
        'report — «${t.line}», who and «${t.kind}», «${t.on}», «${t.keep}» '
        'and «${t.delete}»', (tester) async {
      h.page(1, [reportedComment, reportedReply]);
      await pump(tester, language);

      expect(find.text(t.title), findsOneWidget);
      expect(find.text(t.intro), findsOneWidget);
      expect(find.text(t.line), findsOneWidget);
      expect(find.text(t.kind), findsOneWidget);
      expect(find.text(t.replyKind), findsOneWidget);
      expect(find.text(t.on), findsNWidgets(2));
      expect(find.text(t.keep), findsNWidgets(2));
      expect(find.text(t.delete), findsNWidgets(2));
    });

    testWidgets('E3, E6 [$language]: Keep — «${t.kept}» and the card goes; '
        'Delete asks «${t.askBody}», then «${t.deletedReply}»', (tester) async {
      h.page(1, [reportedComment, reportedReply]);
      await pump(tester, language);

      await tester.tap(find.text(t.keep).first);
      await tester.pumpAndSettle();
      expect(find.text(t.kept), findsOneWidget);
      expect(find.text(t.line), findsNothing);

      await tester.tap(find.text(t.delete));
      await tester.pumpAndSettle();
      expect(find.text(t.askBody), findsOneWidget);
      await tester.tap(find.text(t.delete).last);
      await tester.pumpAndSettle();
      expect(find.text(t.deletedReply), findsOneWidget);
      expect(find.text(t.emptyTitle), findsOneWidget);
      expect(h.badgesRead, 2);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('E9, E10 [$language]: «${t.emptyTitle}»; «${t.error}» and '
        'its retry', (tester) async {
      h.pageFails(1);
      await pump(tester, language);
      expect(find.text(t.error), findsOneWidget);

      h.page(1, const []);
      await tester.tap(find.text(t.retry));
      await tester.pumpAndSettle();
      expect(find.text(t.emptyTitle), findsOneWidget);
      expect(find.text(t.emptyBody), findsOneWidget);
    });
  }

  testWidgets('«On: …» opens the post at the reported reply (D36); back, '
      'the list is read again (S17)', (tester) async {
    final post = PostHarness(post: testPost())..readAnswers(Right(testPost()));
    final comments = CommentsHarness();
    addTearDown(post.dispose);
    addTearDown(comments.dispose);
    comments.page(1, [testComment(id: 10, replyCount: 1)]);
    comments.single(10, Right(testComment(id: 10, replyCount: 1)));
    comments.single(100, Right(testReply(id: 100, parentId: 10)));
    registerPostPage(post, comments);
    h.page(1, [reportedReply]);
    await pump(tester, 'en');

    await tester.tap(find.text('On: الاستخارة والاستشارة'));
    await tester.pumpAndSettle();
    final page = tester.widget<CommunityPostPage>(
      find.byType(CommunityPostPage),
    );
    expect(page.postId, 1);
    expect(page.landing, const CommunityLanding(commentId: 10, replyId: 100));

    await tester.pageBack();
    await tester.pumpAndSettle();
    verify(() => h.getFlags(page: 1)).called(2);
  });
}
