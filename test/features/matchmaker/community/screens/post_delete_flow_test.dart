import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/features/community/domain/entities/community_post_change.dart';
import 'package:qeran/features/community/presentation/screens/community_post_page.dart';
import 'package:qeran/features/community/presentation/widgets/menus/community_menu_button.dart';
import 'package:qeran/features/community/presentation/widgets/post_card/community_post_card.dart';
import 'package:qeran/features/matchmaker/community/presentation/screens/matchmaker_community_screen.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../../community/fixtures/community_comment_fixtures.dart';
import '../../../community/fixtures/community_post_fixtures.dart';
import '../../../community/presentation/blocs/comments/comments_cubit_harness.dart';
import '../../../community/presentation/blocs/post/post_cubit_harness.dart';
import '../../../community/presentation/screens/post_screen_rig.dart';
import '../community_screen_rig.dart';

const _ar = Locale('ar');
const _en = Locale('en');

final _copy = {
  _ar: (
    row: 'حذف المنشور',
    title: 'حذف المنشور؟',
    body:
        'سيُحذف المنشور وكل التعليقات والردود عليه نهائياً ولا يمكن استعادته.',
    delete: 'حذف',
    cancel: 'إلغاء',
    deleted: 'تم حذف المنشور.',
    failed: 'تعذّر حذف المنشور، حاولي مرة أخرى.',
    unavailable: 'هذا المنشور لم يعد متاحاً',
  ),
  _en: (
    row: 'Delete post',
    title: 'Delete post?',
    body:
        'The post and all its comments and replies will be deleted '
        'permanently.',
    delete: 'Delete',
    cancel: 'Cancel',
    deleted: 'Post deleted.',
    failed: 'Couldn’t delete the post. Please try again.',
    unavailable: 'This post is no longer available',
  ),
};

/// Her own post's ⋮ (B6–B9): on «منشوراتي», and on the post's own screen.
void main() {
  late CommunityScreenHarness h;
  setUpAll(initShippedStrings);
  setUp(() {
    h = CommunityScreenHarness();
    h.all.page(1, const []);
    h.myPage(1, [
      testPost(id: 5, text: 'Mine', canDelete: true),
      testPost(id: 4, text: 'Older', canDelete: true),
    ]);
  });
  tearDown(() => h.dispose());

  Finder menuOf(String text) => find.descendant(
    of: find.ancestor(
      of: find.text(text),
      matching: find.byType(CommunityPostCard),
    ),
    matching: find.byType(CommunityMenuButton),
  );

  Future<void> openMine(WidgetTester tester, Locale locale) => pumpHerApp(
    tester,
    const MatchmakerCommunityScreen(initialTab: MatchmakerCommunityTab.mine),
    locale: locale,
  );

  Future<void> askToDelete(WidgetTester tester, Locale locale) async {
    await tester.tap(menuOf('Mine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_copy[locale]!.row));
    await tester.pumpAndSettle();
  }

  for (final locale in [_ar, _en]) {
    final t = _copy[locale]!;

    testWidgets('B6–B8 [${locale.languageCode}]: «${t.row}» alone, asks, '
        'and the post leaves her list', (tester) async {
      h.deleteAnswers(5);
      await openMine(tester, locale);

      await askToDelete(tester, locale);
      expect(find.text(t.title), findsOneWidget);
      expect(find.text(t.body), findsOneWidget);
      await tester.tap(find.text(t.delete));
      await tester.pumpAndSettle();

      expect(find.text('Mine'), findsNothing);
      expect(find.text('Older'), findsOneWidget);
      expect(find.text(t.deleted), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('B9 [${locale.languageCode}]: a delete that fails says so, '
        'and the post stays', (tester) async {
      h.deleteAnswers(5, ok: false);
      await openMine(tester, locale);

      await askToDelete(tester, locale);
      await tester.tap(find.text(t.delete));
      await tester.pumpAndSettle();

      expect(find.text('Mine'), findsOneWidget);
      expect(find.text(t.failed), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });
  }

  testWidgets('B7: Cancel keeps it, and nothing is sent', (tester) async {
    await openMine(tester, _en);

    await askToDelete(tester, _en);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Mine'), findsOneWidget);
    verifyNever(() => h.deletePost(any()));
  });

  testWidgets("someone else's post still offers Report only", (tester) async {
    h.myPage(1, const []);
    h.all.page(1, [testPost(id: 9, text: 'Theirs')]);
    await pumpHerApp(tester, const MatchmakerCommunityScreen());

    await tester.tap(menuOf('Theirs'));
    await tester.pumpAndSettle();

    expect(find.text('Report post'), findsOneWidget);
    expect(find.text('Delete post'), findsNothing);
  });

  testWidgets('S8: from her post\'s own screen, it closes onto her list with '
      'the toast — never «${_copy[_en]!.unavailable}»', (tester) async {
    final post = PostHarness();
    when(() => post.getPost(5)).thenAnswer(
      (_) async => Right(testPost(id: 5, text: 'Mine', canDelete: true)),
    );
    final comments = CommentsHarness();
    when(
      () => comments.getComments(5, page: 1),
    ).thenAnswer((_) async => Right(commentPage([testComment()])));
    registerPostPage(post, comments, deletePost: h.deletePost);
    when(() => h.deletePost(5)).thenAnswer((_) async {
      // The repository's one stream, as the post page and her list hear it.
      post.changes.add(const CommunityPostGone(5));
      h.all.changes.add(const CommunityPostGone(5));
      return const Right(unit);
    });
    addTearDown(() async {
      await post.dispose();
      await comments.dispose();
    });
    await openMine(tester, _en);
    await tester.tap(find.text('Discuss').first);
    await tester.pumpAndSettle();
    expect(find.byType(CommunityPostPage), findsOneWidget);

    await tester.tap(menuOf('Mine').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump();
    expect(find.text(_copy[_en]!.unavailable), findsNothing);
    await tester.pumpAndSettle();

    expect(find.byType(CommunityPostPage), findsNothing);
    expect(find.text('Mine'), findsNothing);
    expect(find.text('Post deleted.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
