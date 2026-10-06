import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/community/domain/entities/community_media.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/domain/entities/community_viewer.dart';
import 'package:qeran/features/community/presentation/widgets/menus/community_menu_button.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../../auth/presentation/fake_session.dart';
import '../../../profile/presentation/fake_profile_gate.dart';
import '../../fixtures/community_comment_fixtures.dart';
import '../../fixtures/community_post_fixtures.dart';
import '../blocs/comments/comments_cubit_harness.dart';
import '../blocs/post/post_cubit_harness.dart';
import 'post_screen_rig.dart';
import 'report_rig.dart';

/// The shared post screen in her app (Phase 3, sub-step 4): never gated,
/// spoken to in the feminine, and her delete of someone else's comment says
/// so. The member's screen is unchanged.
void main() {
  late PostHarness post;
  late CommentsHarness comments;
  setUpAll(initShippedStrings);
  setUp(() {
    post = PostHarness(post: testPost(canDelete: true));
    comments = CommentsHarness();
  });
  tearDown(() async {
    await sl.reset();
    await post.dispose();
    await comments.dispose();
  });

  Future<void> pumpHers(WidgetTester tester, {Locale? locale}) {
    signInForTest();
    return pumpPostScreen(
      tester,
      post,
      comments,
      locale: locale ?? const Locale('ar'),
      gateCubit: UnreadGate(),
      viewer: CommunityViewer.matchmaker,
    );
  }

  testWidgets('ar: never gated, and the empty discussion and the field '
      'speak to her (Q9)', (tester) async {
    comments.page(1, const []);
    await comments.cubit.load();
    await pumpHers(tester);

    expect(find.text('كوني أول من يبدأ النقاش.'), findsOneWidget);
    expect(find.text('اكتبي تعليقاً…'), findsOneWidget);
  });

  testWidgets("ar: the member's screen keeps the generic form", (tester) async {
    comments.page(1, const []);
    await comments.cubit.load();
    await pumpPostScreen(
      tester,
      post,
      comments,
      locale: const Locale('ar'),
      gate: ProfileStatus.visible,
    );

    expect(find.text('كن أول من يبدأ النقاش.'), findsOneWidget);
    expect(find.text('اكتب تعليقاً…'), findsOneWidget);
  });

  for (final (locale, delete, title, body) in [
    (
      const Locale('ar'),
      'حذف التعليق',
      'حذف التعليق؟',
      'سيُحذف هذا التعليق وكل الردود عليه نهائياً ولا يمكن استعادته.',
    ),
    (
      const Locale('en'),
      'Delete comment',
      'Delete comment?',
      'This comment and all its replies will be deleted permanently.',
    ),
  ]) {
    testWidgets('${locale.languageCode}: deleting a member\'s comment on her '
        'post names it, not «تعليقك» (E4)', (tester) async {
      comments.page(1, [testComment(id: 10, canDelete: true)]);
      await comments.cubit.load();
      await pumpHers(tester, locale: locale);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('comment-10')),
          matching: find.byType(CommunityMenuButton),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(delete));
      await tester.pumpAndSettle();

      expect(find.text(title), findsOneWidget);
      expect(find.text(body), findsOneWidget);
    });
  }

  testWidgets('ar: her report note speaks to her (Q9)', (tester) async {
    registerReporting(FakeReporter());
    comments.page(1, [testComment(id: 10)]);
    await comments.cubit.load();
    await pumpHers(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('comment-10')),
        matching: find.byType(CommunityMenuButton),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإبلاغ عن التعليق'));
    await tester.pumpAndSettle();

    expect(find.text('أضيفي ملاحظة (اختياري)'), findsOneWidget);
  });

  testWidgets('BA-A2: her post that failed — the card alone: no «النقاش», no '
      'comments, no field', (tester) async {
    final unused = post;
    addTearDown(unused.dispose);
    post = PostHarness(
      post: testPost(
        canDelete: true,
        status: CommunityPostStatus.failed,
        media: CommunitySingleVideo(testVideo(url: null)),
      ),
    );
    comments.page(1, [testComment(id: 10)]);
    await comments.cubit.load();
    await pumpHers(tester);

    expect(find.text('تعذّرت معالجة الفيديو'), findsWidgets);
    expect(find.text('النقاش'), findsNothing);
    expect(find.text(saraText), findsNothing);
    expect(find.text('اكتبي تعليقاً…'), findsNothing);
  });
}
