import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/widgets/qeran_composer.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/comment_submit_outcome.dart';
import 'package:qeran/features/community/presentation/widgets/composer/community_composer.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../fixtures/community_comment_fixtures.dart';
import '../../fixtures/community_post_fixtures.dart';
import '../blocs/comments/comments_cubit_harness.dart';
import '../blocs/post/post_cubit_harness.dart';
import 'post_screen_rig.dart';

const _question = 'When is the right time to ask for the viewing?';

Future<void> _write(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.tap(find.byType(QeranSendButton));
  await tester.pump();
  await tester.pump();
}

void main() {
  late PostHarness post;
  late CommentsHarness comments;
  setUpAll(initShippedStrings);
  setUp(() async {
    post = PostHarness(post: testPost(commentCount: 2));
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

  testWidgets('D5–D6: a comment shows at the top, «جارٍ النشر…», until the '
      'server has it; then the post\'s counts are read again', (tester) async {
    final answer = Completer<Either<Failure, CommentSubmitOutcome>>();
    when(
      () => comments.createComment(1, _question),
    ).thenAnswer((_) => answer.future);
    await pumpPostScreen(tester, post, comments);

    await _write(tester, _question);
    expect(find.text('Posting…'), findsOneWidget);
    final mine = tester.getTopLeft(find.text(_question)).dy;
    expect(mine, lessThan(tester.getTopLeft(find.text(saraText)).dy));

    answer.complete(Right(CommentPosted(testComment(id: 99, text: _question))));
    await tester.pumpAndSettle();
    expect(find.text('Posting…'), findsNothing);
    expect(find.text(_question), findsOneWidget);
    verify(() => comments.getPost(1)).called(1);
  });

  testWidgets('D7: failed — the row says so; a tap sends it again', (
    tester,
  ) async {
    comments.commentAnswers(const Left(OfflineFailure()));
    await pumpPostScreen(tester, post, comments);
    await _write(tester, _question);
    await tester.pumpAndSettle();

    comments.commentAnswers(Right(CommentPosted(testComment(id: 99))));
    await tester.tap(find.text('Not posted · Tap to retry'));
    await tester.pumpAndSettle();

    verify(() => comments.createComment(1, _question)).called(2);
    expect(find.text('Not posted · Tap to retry'), findsNothing);
  });

  testWidgets('D2, D10: Reply — the strip; the reply goes under its comment', (
    tester,
  ) async {
    comments.replyAnswers(10, Right(CommentPosted(testReply(id: 98))));
    await pumpPostScreen(tester, post, comments);

    await tester.tap(find.text('Reply').first);
    await tester.pump();
    await tester.pump();
    expect(find.text('Replying to'), findsOneWidget);

    await _write(tester, 'Thank you');
    await tester.pumpAndSettle();

    verify(() => comments.createReply(10, 'Thank you')).called(1);
    expect(find.text('Replying to'), findsNothing);
    final reply = tester.getTopLeft(find.text(hudaReply)).dy;
    expect(reply, greaterThan(tester.getTopLeft(find.text(saraText)).dy));
    expect(reply, lessThan(tester.getTopLeft(find.text(fahadText)).dy));
  });

  testWidgets('C10: a member not approved yet — why, no field, no Reply', (
    tester,
  ) async {
    await pumpPostScreen(
      tester,
      post,
      comments,
      gate: ProfileStatus.pendingReview,
    );

    expect(
      find.text('You can comment and reply once your profile is approved.'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Reply'), findsNothing);
  });

  group('J2: an iPhone SE, replying, the keyboard up', () {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      testWidgets(locale.languageCode, (tester) async {
        tester.view.viewInsets = const FakeViewPadding(bottom: 216);
        addTearDown(tester.view.resetViewInsets);
        await pumpPostScreen(
          tester,
          post,
          comments,
          locale: locale,
          size: const Size(375, 667),
        );

        await tester.tap(find.byIcon(Icons.reply_rounded).first);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'a ' * 300);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final bar = tester.getRect(find.byType(CommunityComposer));
        expect(bar.bottom, lessThanOrEqualTo(667 - 216));
      });
    }
  });
}
