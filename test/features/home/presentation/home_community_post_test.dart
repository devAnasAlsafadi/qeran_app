import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/community/presentation/screens/community_post_page.dart';
import 'package:qeran/features/home/presentation/home_community_post.dart';
import 'package:qeran/features/notifications/presentation/routing/notification_deep_link.dart';

import '../../../core/shipped_strings_rig.dart';
import '../../community/fixtures/community_post_fixtures.dart';
import '../../community/presentation/blocs/comments/comments_cubit_harness.dart';
import '../../community/presentation/blocs/post/post_cubit_harness.dart';
import '../../community/presentation/screens/post_screen_rig.dart';

/// A pushed post from a notification, over a chat that was open: back
/// returns to the chat; «العودة إلى المجتمع» pops to the shell (Q12).
void main() {
  late PostHarness post;
  late CommentsHarness comments;
  late BuildContext shell;
  bool? answer;
  setUpAll(initShippedStrings);
  setUp(() async {
    await sl.reset();
    answer = null;
    post = PostHarness();
    comments = CommentsHarness();
    comments.page(1, const []);
    registerPostPage(post, comments);
  });
  tearDown(() async {
    AppSnackBar.debugReset();
    await post.dispose();
    await comments.dispose();
    await sl.reset();
  });

  /// The shell, a chat pushed over it, then the post over both.
  Future<void> openOverChat(WidgetTester tester) async {
    await pumpShippedStrings(
      tester,
      const Locale('en'),
      builder: (_, navigator) => postScreenLayers(navigator!),
      child: Builder(
        builder: (context) {
          shell = context;
          return const Text('shell');
        },
      ),
    );
    Navigator.of(
      shell,
    ).push(MaterialPageRoute<void>(builder: (_) => const Text('chat')));
    await tester.pumpAndSettle();
    openPostOverShell(
      shell,
      const OpenCommunityPost(postId: 1),
    ).then((back) => answer = back);
    await tester.pumpAndSettle();
  }

  testWidgets('back: the chat again, and no Community', (tester) async {
    post.readAnswers(Right(testPost()));
    await openOverChat(tester);

    Navigator.of(tester.element(find.byType(CommunityPostPage))).pop();
    await tester.pumpAndSettle();

    expect(find.text('chat'), findsOneWidget);
    expect(answer, isFalse);
  });

  testWidgets('gone: «العودة إلى المجتمع» pops the chat too', (tester) async {
    post.readAnswers(const Left(postNotFound));
    await openOverChat(tester);

    await tester.tap(find.text('Back to Community'));
    await tester.pumpAndSettle();

    expect(find.text('shell'), findsOneWidget);
    expect(find.text('chat', skipOffstage: false), findsNothing);
    expect(answer, isTrue);
  });
}
