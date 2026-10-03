import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/community_like_state.dart';
import 'package:qeran/features/community/domain/entities/community_viewer.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../fixtures/community_comment_fixtures.dart';
import '../../fixtures/community_post_fixtures.dart';
import '../blocs/comments/comments_cubit_harness.dart';
import '../blocs/post/post_cubit_harness.dart';
import 'post_screen_rig.dart';

void main() {
  late PostHarness post;
  late CommentsHarness comments;
  setUpAll(initShippedStrings);
  setUp(() async {
    post = PostHarness(post: testPost());
    comments = CommentsHarness();
    comments.page(1, [
      testComment(id: 10),
      testComment(id: 11, author: fahad, text: fahadText),
    ]);
    await comments.cubit.load();
  });
  tearDown(() async {
    await post.dispose();
    await comments.dispose();
  });

  group('likes', () {
    testWidgets('the post\'s Like goes to the post', (tester) async {
      post.likeAnswers(
        const Right(CommunityLikeState(likeCount: 1, likedByMe: true)),
      );
      await pumpPostScreen(tester, post, comments);

      await tester.tap(cardLike);
      await tester.pumpAndSettle();

      verify(() => post.setLike(1, liked: true)).called(1);
    });

    testWidgets('a comment\'s that fails: taken back, with a toast', (
      tester,
    ) async {
      comments.likeAnswers(11, const Left(ServerFailure(message: 'x')));
      await pumpPostScreen(tester, post, comments);

      await tester.tap(find.text('Like').last);
      await tester.pump();

      expect(
        find.text('Couldn’t save your like. Please try again.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('a member not approved yet: dimmed, told why, nothing sent '
        '(D9)', (tester) async {
      await pumpPostScreen(
        tester,
        post,
        comments,
        gate: ProfileStatus.pendingReview,
      );

      await tester.tap(cardLike);
      await tester.pump();

      expect(
        find.text('You can like once your profile is approved.'),
        findsOneWidget,
      );
      verifyNever(() => post.setLike(any(), liked: any(named: 'liked')));
      await tester.pump(const Duration(seconds: 5));
    });
  });

  testWidgets('a matchmaker is never gated: her Likes go out', (tester) async {
    post.likeAnswers(
      const Right(CommunityLikeState(likeCount: 1, likedByMe: true)),
    );
    await pumpPostScreen(
      tester,
      post,
      comments,
      gate: ProfileStatus.pendingReview,
      viewer: CommunityViewer.matchmaker,
    );

    final dimmers = tester.widgetList<Opacity>(
      find.ancestor(of: find.text('Like'), matching: find.byType(Opacity)),
    );
    expect({for (final o in dimmers) o.opacity}, {1.0});
    await tester.tap(cardLike);
    await tester.pumpAndSettle();
    verify(() => post.setLike(1, liked: true)).called(1);
  });
}
