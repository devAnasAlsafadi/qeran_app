import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/presentation/widgets/comments/comments_skeleton.dart';
import 'package:qeran/features/community/presentation/widgets/feed/community_feed_skeleton.dart';
import 'package:qeran/features/community/presentation/widgets/post_screen/community_post_unavailable.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../fixtures/community_comment_fixtures.dart';
import '../../fixtures/community_post_fixtures.dart';
import '../blocs/comments/comments_cubit_harness.dart';
import '../blocs/post/post_cubit_harness.dart';
import 'post_screen_rig.dart';

/// The state's button is as wide as its label and side padding — not the
/// whole column.
void _expectButtonHugs(WidgetTester tester) {
  final button = find.byType(QeranButton);
  final label = find.descendant(of: button, matching: find.byType(Row));
  expect(tester.getSize(button).width, tester.getSize(label).width + 2 * 24);
}

void main() {
  late PostHarness post;
  late CommentsHarness comments;
  setUpAll(initShippedStrings);
  setUp(() {
    post = PostHarness(post: testPost());
    comments = CommentsHarness();
  });
  tearDown(() async {
    await post.dispose();
    await comments.dispose();
  });

  group('C4: no comments yet', () {
    setUp(() async {
      comments.page(1, const []);
      await comments.cubit.load();
    });

    testWidgets('an invitation to start', (tester) async {
      await pumpPostScreen(tester, post, comments);

      expect(find.text('No comments yet'), findsOneWidget);
      expect(
        find.text('Be the first to start the discussion.'),
        findsOneWidget,
      );
    });

    testWidgets('read-only: where they\'ll appear', (tester) async {
      await pumpPostScreen(
        tester,
        post,
        comments,
        gate: ProfileStatus.pendingReview,
      );

      expect(find.text('Comments will appear here.'), findsOneWidget);
      expect(find.text('Be the first to start the discussion.'), findsNothing);
    });
  });

  testWidgets('C5: the comments on their way: skeleton rows', (tester) async {
    await pumpPostScreen(tester, post, comments, settle: false);

    expect(find.byType(CommentsSkeleton), findsOneWidget);
    expect(find.text(istikhara), findsOneWidget);
  });

  testWidgets('C6: the comments failed; the retry asks again', (tester) async {
    comments.pageFails(1);
    await comments.cubit.load();
    await pumpPostScreen(tester, post, comments);
    expect(find.text("Couldn't load comments"), findsOneWidget);
    _expectButtonHugs(tester);

    comments.page(1, [testComment()]);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    verify(() => comments.getComments(1, page: 1)).called(2);
    expect(find.text(saraText), findsOneWidget);
  });

  testWidgets('C7: the post is gone: why, and the way back', (tester) async {
    post.readAnswers(const Left(postNotFound));
    await post.cubit.load();
    await pumpPostScreen(tester, post, comments, settle: false);

    expect(find.text('This post is no longer available'), findsOneWidget);
    expect(
      find.text('The post or comment you opened may have been removed.'),
      findsOneWidget,
    );
    expect(find.text('Back to Community'), findsOneWidget);
    expect(find.text(istikhara), findsNothing);
  });

  testWidgets('C7: its button hugs its label', (tester) async {
    // At half size, so the test font's square glyphs leave the label room.
    await pumpShippedStrings(
      tester,
      const Locale('en'),
      child: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(0.5)),
        child: CommunityPostUnavailable(onBack: () {}),
      ),
    );

    _expectButtonHugs(tester);
  });

  group('opened without a copy of the post', () {
    setUp(() async {
      await post.dispose();
      post = PostHarness();
    });

    testWidgets('on its way: a card\'s shape and the rows\'', (tester) async {
      final never = Completer<Either<Failure, CommunityPost>>();
      when(() => post.getPost(1)).thenAnswer((_) => never.future);
      unawaited(post.cubit.load());
      await pumpPostScreen(tester, post, comments, settle: false);

      expect(find.byType(CommunityFeedSkeleton), findsOneWidget);
      expect(find.byType(CommentsSkeleton), findsOneWidget);
    });

    testWidgets('it can\'t be read: the error; the retry reads again', (
      tester,
    ) async {
      post.readAnswers(const Left(OfflineFailure()));
      await post.cubit.load();
      await pumpPostScreen(tester, post, comments, settle: false);
      expect(find.text("Couldn't load the post"), findsOneWidget);

      post.readAnswers(Right(testPost()));
      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump();

      expect(find.text(istikhara), findsOneWidget);
    });
  });

  group('J: an iPhone SE (375 × 667), gated, nothing overflows', () {
    // Outside the test's fake clock: closing a cubit waits on real time.
    setUp(() async {
      await post.dispose();
      post = PostHarness(
        post: testPost(author: ummAbdulrahman, commentCount: 1240),
      );
      comments.page(1, [
        testComment(id: 10, replyCount: 12, likeCount: 1240),
        testComment(id: 11, author: fahad, text: fahadText),
      ], totalPages: 2);
      comments.replies(
        10,
        1,
        [testReply(author: ummAbdulrahman)],
        totalPages: 2,
        totalCount: 12,
      );
      await comments.cubit.load();
      await comments.cubit.showReplies(10);
    });

    for (final locale in const [Locale('ar'), Locale('en')]) {
      testWidgets(locale.languageCode, (tester) async {
        await pumpPostScreen(
          tester,
          post,
          comments,
          locale: locale,
          gate: ProfileStatus.pendingReview,
          size: const Size(375, 667),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
