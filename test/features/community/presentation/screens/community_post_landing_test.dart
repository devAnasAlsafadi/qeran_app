import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/community_landing.dart';
import 'package:qeran/features/community/presentation/widgets/comments/comments_header.dart';
import 'package:qeran/features/community/presentation/widgets/post_card/community_post_card.dart';
import 'package:qeran/features/community/presentation/widgets/post_screen/community_post_unavailable.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../fixtures/community_comment_fixtures.dart';
import '../../fixtures/community_post_fixtures.dart';
import '../blocs/comments/comments_cubit_harness.dart';
import '../blocs/post/post_cubit_harness.dart';
import 'post_screen_rig.dart';

/// Both UI languages: what the replies link says under the landed reply,
/// and the word that the content is gone.
final _copy = {
  const Locale('ar'): (
    more: 'عرض ردّين آخرين',
    gone: 'هذا المحتوى لم يعد متاحاً.',
  ),
  const Locale('en'): (
    more: 'View 2 more replies',
    gone: 'This content is no longer available.',
  ),
};

/// Opened from "New reply to your comment" (C8): «النقاش» scrolled to the
/// top, my comment under it, the new reply in gold for 2 s, then the rest
/// behind «عرض ردود أخرى».
void main() {
  const myText = 'أوافقكِ، السؤال عن الخاطب أهم خطوة.';
  final mine = testComment(id: 20, replyCount: 3, isMine: true, text: myText);
  final reply = testReply(
    id: 203,
    parentId: 20,
    author: fahad,
    text: fahadText,
  );
  late PostHarness post;
  late CommentsHarness discussion;
  setUpAll(initShippedStrings);
  setUp(() {
    // Long enough that «النقاش» starts below the fold.
    post = PostHarness(
      post: testPost(text: List.filled(8, istikhara).join('\n\n')),
    );
    discussion = CommentsHarness(
      landing: const CommunityLanding(commentId: 20, replyId: 203),
    );
    discussion.single(20, Right(mine));
    discussion.single(203, Right(reply));
    discussion.page(1, comments(30, 31));
  });
  tearDown(() async {
    await post.dispose();
    await discussion.dispose();
  });

  Future<void> pump(WidgetTester tester, Locale locale, {bool settle = true}) =>
      pumpPostScreen(
        tester,
        post,
        discussion,
        locale: locale,
        size: const Size(390, 640),
        settle: settle,
      );

  Color? background(WidgetTester tester, String text) {
    final row = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text(text),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    return (row.decoration as BoxDecoration?)?.color;
  }

  for (final MapEntry(key: locale, value: copy) in _copy.entries) {
    testWidgets('${locale.languageCode}: «النقاش» at the top, the reply in '
        'gold under my comment, then «عرض ردود أخرى»', (tester) async {
      await discussion.cubit.load();
      await pump(tester, locale);

      expect(tester.getTopLeft(find.byType(CommentsHeader)).dy, 0);
      expect(
        tester.getTopLeft(find.text(myText)).dy,
        lessThan(tester.getTopLeft(find.text(fahadText)).dy),
      );
      expect(background(tester, fahadText), QeranColors.gold12);
      expect(background(tester, myText)?.a, 0);
      expect(find.text(copy.more), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(background(tester, fahadText)?.a, 0);
    });
  }

  testWidgets('comments that land after the post is shown are revealed '
      'then', (tester) async {
    // The comments' skeleton never settles: frames by hand.
    await pump(tester, const Locale('en'), settle: false);
    await tester.pump();
    expect(find.byType(CommentsHeader), findsNothing, reason: 'below the fold');

    await discussion.cubit.load();
    // The rows land; the scroll starts after that frame, and ends.
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.getTopLeft(find.byType(CommentsHeader)).dy, 0);
    expect(background(tester, fahadText), QeranColors.gold12);
    await tester.pump(const Duration(seconds: 2));
  });

  for (final MapEntry(key: locale, value: copy) in _copy.entries) {
    testWidgets('${locale.languageCode}: the reply gone — the post as it '
        'is, no gold, and the word that it\'s gone', (tester) async {
      discussion.single(
        203,
        const Left(
          CodedServerFailure(message: 'x', errorCode: 'COMMENT_NOT_FOUND'),
        ),
      );
      await pump(tester, locale, settle: false);
      await discussion.cubit.load();
      await tester.pump();
      await tester.pump();

      expect(find.text(copy.gone), findsOneWidget);
      expect(find.byType(CommunityPostCard), findsOneWidget);
      expect(find.byType(CommunityPostUnavailable), findsNothing);
      expect(find.text(myText), findsNothing, reason: 'no pin');
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is AnimatedContainer &&
              (w.decoration as BoxDecoration?)?.color == QeranColors.gold12,
        ),
        findsNothing,
        reason: 'no gold',
      );
      await tester.pump(const Duration(seconds: 5));
    });
  }
}
