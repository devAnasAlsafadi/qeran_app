import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/community_viewer.dart';
import 'package:qeran/features/community/presentation/widgets/menus/community_menu_button.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../fixtures/community_comment_fixtures.dart';
import '../../fixtures/community_post_fixtures.dart';
import '../blocs/comments/comments_cubit_harness.dart';
import '../blocs/post/post_cubit_harness.dart';
import 'post_screen_rig.dart';

/// Delete and Block from a row's ⋮ (E8–E12, I1): each asks first, and what
/// goes leaves the list while the screen stays.
void main() {
  late PostHarness post;
  late CommentsHarness comments;
  final blocked = <String>[];

  setUpAll(initShippedStrings);
  setUp(() async {
    blocked.clear();
    post = PostHarness(post: testPost(commentCount: 4));
    comments = CommentsHarness();
    comments.page(1, [
      testComment(id: 10, author: fahad, replyCount: 1),
      testComment(id: 11, author: sara, isMine: true, canDelete: true),
      testComment(id: 12, replyCount: 1),
    ]);
    comments.replies(10, 1, [testReply(id: 100, author: sara, isMine: true)]);
    comments.replies(12, 1, [testReply(id: 120, parentId: 12, author: fahad)]);
    await comments.cubit.load();
    await comments.cubit.showReplies(10);
    await comments.cubit.showReplies(12);
  });
  tearDown(() async {
    await post.dispose();
    await comments.dispose();
  });

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    CommunityViewer viewer = CommunityViewer.member,
  }) => pumpPostScreen(
    tester,
    post,
    comments,
    locale: locale,
    viewer: viewer,
    block: (id) async {
      blocked.add(id);
      return const Right(null);
    },
  );

  Finder row(int id) => find.byKey(ValueKey('comment-$id'));

  Future<void> choose(WidgetTester tester, int id, String option) async {
    await tester.tap(
      find.descendant(of: row(id), matching: find.byType(CommunityMenuButton)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(option));
    await tester.pumpAndSettle();
  }

  Future<void> toastDone(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testWidgets('E8, E9: my comment asks, then goes with a toast [ar]', (
    tester,
  ) async {
    when(() => comments.delete(11)).thenAnswer((_) async => const Right(unit));
    await pump(tester, locale: const Locale('ar'));

    await choose(tester, 11, 'حذف التعليق');
    expect(find.text('حذف التعليق؟'), findsOneWidget);
    expect(
      find.text('سيُحذف تعليقك وكل الردود عليه نهائياً ولا يمكن استعادته.'),
      findsOneWidget,
    );
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();

    expect(row(11), findsNothing);
    expect(find.text('تم حذف التعليق.'), findsOneWidget);
    await toastDone(tester);
  });

  testWidgets('E8b, S14: my reply, in its own words', (tester) async {
    when(() => comments.delete(100)).thenAnswer((_) async => const Right(unit));
    await pump(tester);

    await choose(tester, 100, 'Delete reply');
    expect(find.text('Delete reply?'), findsOne);
    expect(find.text('Your reply will be deleted permanently.'), findsOne);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(row(100), findsNothing);
    expect(find.text('Reply deleted.'), findsOneWidget);
    await toastDone(tester);
  });

  testWidgets("S14: a reply's dialog says «الرد» [ar]", (tester) async {
    await pump(tester, locale: const Locale('ar'));

    await choose(tester, 100, 'حذف الرد');
    expect(find.text('حذف الرد؟'), findsOneWidget);
    expect(find.text('سيُحذف ردّك نهائياً ولا يمكن استعادته.'), findsOneWidget);
    expect(find.text('حذف التعليق؟'), findsNothing);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    verifyNever(() => comments.delete(any()));
  });

  testWidgets('cancelled: nothing is deleted', (tester) async {
    await pump(tester);

    await choose(tester, 11, 'Delete comment');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(row(11), findsOneWidget);
    verifyNever(() => comments.delete(any()));
  });

  // A failed delete, by the menu row chosen: a reply's in its own words
  // (Anas, 2026-10-04), in English and Arabic.
  const failures = {
    'Delete comment': "Couldn't delete the comment. Please try again.",
    'Delete reply': "Couldn't delete the reply. Please try again.",
    'حذف الرد': 'تعذّر حذف الرد، حاول مرة أخرى.',
  };
  for (final MapEntry(key: option, value: said) in failures.entries) {
    final id = option == 'Delete comment' ? 11 : 100;
    final arabic = option == 'حذف الرد';
    testWidgets('E10: a failed delete keeps the row and says so — $option', (
      tester,
    ) async {
      when(
        () => comments.delete(id),
      ).thenAnswer((_) async => const Left(OfflineFailure()));
      await pump(tester, locale: Locale(arabic ? 'ar' : 'en'));

      await choose(tester, id, option);
      await tester.tap(find.text(arabic ? 'حذف' : 'Delete'));
      await tester.pumpAndSettle();

      expect(row(id), findsOneWidget);
      expect(find.text(said), findsOneWidget);
      await toastDone(tester);
    });
  }

  testWidgets('E11, E12: Block asks, then every row of theirs goes and the '
      'screen stays', (tester) async {
    await pump(tester);

    await choose(tester, 10, 'Block user');
    expect(find.text('Block this user?'), findsOneWidget);
    await tester.tap(find.text('Block'));
    await tester.pumpAndSettle();

    expect(blocked, [fahad.id]);
    expect(row(10), findsNothing);
    expect(row(120), findsNothing);
    expect(row(12), findsOneWidget);
    expect(find.text('User blocked.'), findsOneWidget);
    await toastDone(tester);
  });

  testWidgets('I1: a matchmaker on her post — Delete and Report, no Block', (
    tester,
  ) async {
    comments.page(1, [testComment(id: 13, canDelete: true, canBlock: true)]);
    await comments.cubit.load();
    await pump(tester, viewer: CommunityViewer.matchmaker);

    await tester.tap(
      find.descendant(of: row(13), matching: find.byType(CommunityMenuButton)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delete comment'), findsOneWidget);
    expect(find.text('Report comment'), findsOneWidget);
    expect(find.text('Block user'), findsNothing);
  });
}
