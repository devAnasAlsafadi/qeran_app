import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/features/community/presentation/widgets/comments/comments_header.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../fixtures/community_comment_fixtures.dart';
import '../../fixtures/community_post_fixtures.dart';
import '../blocs/comments/comments_cubit_harness.dart';
import '../blocs/post/post_cubit_harness.dart';
import 'post_screen_rig.dart';

/// Both UI languages, and what each one writes.
final _copy = {
  const Locale('ar'): (
    discussion: 'النقاش',
    replies: 'عرض 3 ردود',
    more: 'عرض تعليقات أخرى',
  ),
  const Locale('en'): (
    discussion: 'Discussion',
    replies: 'View 3 replies',
    more: 'View more comments',
  ),
};

void main() {
  late PostHarness post;
  late CommentsHarness comments;
  setUpAll(initShippedStrings);
  setUp(() async {
    post = PostHarness(post: testPost(commentCount: 14));
    comments = CommentsHarness();
    comments.page(1, [
      testComment(id: 10, replyCount: 3, likeCount: 12),
      testComment(id: 11, author: fahad, text: fahadText),
    ], totalPages: 2);
    await comments.cubit.load();
  });
  tearDown(() async {
    await post.dispose();
    await comments.dispose();
  });

  group('C1: the post, «النقاش» and its count, the comments', () {
    for (final MapEntry(key: locale, value: copy) in _copy.entries) {
      testWidgets(locale.languageCode, (tester) async {
        await pumpPostScreen(tester, post, comments, locale: locale);

        expect(find.text(istikhara), findsOneWidget);
        final header = find.byType(CommentsHeader);
        expect(
          find.descendant(of: header, matching: find.text(copy.discussion)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: header, matching: find.text('14')),
          findsOneWidget,
        );
        expect(find.text(sara.displayName), findsOneWidget);
        expect(find.text(fahad.displayName), findsOneWidget);
        expect(find.text(copy.replies), findsOneWidget);
        expect(find.text(copy.more), findsOneWidget);
      });
    }
  });

  testWidgets('C2: «عرض الردود» opens the thread, oldest first, and offers '
      'the rest', (tester) async {
    comments.replies(
      10,
      1,
      [testReply(id: 100), testReply(id: 101, text: 'ثاني ردّ')],
      totalPages: 2,
      totalCount: 3,
    );
    await pumpPostScreen(tester, post, comments);

    await tester.tap(find.text('View 3 replies'));
    await tester.pumpAndSettle();

    final first = tester.getTopLeft(find.text(hudaReply)).dy;
    expect(first, lessThan(tester.getTopLeft(find.text('ثاني ردّ')).dy));
    expect(find.text('View 1 more reply'), findsOneWidget);
  });

  testWidgets('C3: «عرض تعليقات أخرى» → a loader → the next comments', (
    tester,
  ) async {
    final answer = Completer<CommentsAnswer>();
    when(
      () => comments.getComments(1, page: 2),
    ).thenAnswer((_) => answer.future);
    await pumpPostScreen(tester, post, comments);

    await tester.tap(find.text('View more comments'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(QeranLoader), findsOneWidget);

    answer.complete(
      Right(
        commentPage(
          [testComment(id: 12, text: 'نسأل الله التيسير للجميع.')],
          page: 2,
          totalPages: 2,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('نسأل الله التيسير للجميع.'), findsOneWidget);
    expect(find.text('View more comments'), findsNothing);
  });

  testWidgets('pull to refresh: the post read again, and the first page of '
      'comments', (tester) async {
    post.readAnswers(Right(testPost(commentCount: 15)));
    await pumpPostScreen(tester, post, comments);

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    verify(() => post.getPost(1)).called(1);
    verify(() => comments.getComments(1, page: 1)).called(2);
    expect(
      find.descendant(
        of: find.byType(CommentsHeader),
        matching: find.text('15'),
      ),
      findsOneWidget,
    );
  });
}
