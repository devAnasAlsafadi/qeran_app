import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/community/domain/entities/community_viewer.dart';
import 'package:qeran/features/community/presentation/screens/community_post_page.dart';
import 'package:qeran/features/matchmaker/community/presentation/screens/community_reports_page.dart';

import '../../../core/shipped_strings_rig.dart';
import '../../community/fixtures/community_comment_fixtures.dart';
import '../../community/fixtures/community_post_fixtures.dart';
import '../../community/presentation/blocs/comments/comments_cubit_harness.dart';
import '../../community/presentation/blocs/post/post_cubit_harness.dart';
import '../../community/presentation/screens/post_screen_rig.dart';
import '../notifications/her_community_notifications.dart';
import 'her_shell_rig.dart';

/// A Community push she taps outside the app opens the post over her shell,
/// at its item (C8, D36), and raises no trail: back is where she was.
void main() {
  late PostHarness post;
  late CommentsHarness comments;
  setUpAll(initShippedStrings);
  setUp(() {
    post = PostHarness()..readAnswers(Right(testPost(commentCount: 2)));
    comments = CommentsHarness()
      ..single(10, Right(testComment(id: 10, replyCount: 1)))
      ..single(100, Right(testReply(id: 100)))
      ..page(1, [testComment(id: 11)]);
  });
  tearDown(() async {
    AppSnackBar.debugReset();
    await post.dispose();
    await comments.dispose();
    await sl.reset();
  });

  HerShellRig shellWith({Map<String, dynamic>? launchedBy}) {
    final shell = HerShellRig(
      launchedBy: launchedBy == null ? null : push(launchedBy),
      layers: postScreenLayers,
    );
    registerPostPage(post, comments);
    return shell;
  }

  CommunityPostPage page(WidgetTester tester) =>
      tester.widget<CommunityPostPage>(find.byType(CommunityPostPage));

  testWidgets('a report tapped in the background: the post over the shell, '
      'at the reported reply, as her — never «البلاغات»; back is the '
      'Dashboard, with no trail', (tester) async {
    final shell = shellWith();
    await shell.pump(tester);

    shell.opened.add(push(herReport.data));
    await tester.pumpAndSettle();

    expect(
      (page(tester).postId, page(tester).viewer),
      (1, CommunityViewer.matchmaker),
    );
    verify(() => comments.getComment(10)).called(1);
    verify(() => comments.getComment(100)).called(1);
    expect(find.byType(CommunityReportsScreen), findsNothing);
    expect(shell.trail(tester), isFalse);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(CommunityPostPage), findsNothing);
    expect((shell.tab(tester), shell.trail(tester)), (0, false));
  });

  testWidgets('a new comment whose tap launched the app (killed): the post at '
      'the comment', (tester) async {
    final shell = shellWith(launchedBy: herComment.data);
    await shell.pump(tester);

    expect(page(tester).postId, 1);
    verify(() => comments.getComment(10)).called(1);
    verifyNever(() => comments.getComment(100));
  });

  testWidgets('a reply to her comment (D31) opens it; the same reply sent to '
      'a member does nothing here', (tester) async {
    final shell = shellWith();
    await shell.pump(tester);

    shell.opened.add(push({...herReply.data, 'audience': 'member'}));
    await tester.pumpAndSettle();
    expect(find.byType(CommunityPostPage), findsNothing);

    shell.opened.add(push(herReply.data));
    await tester.pumpAndSettle();
    verify(() => comments.getComment(100)).called(1);
  });
}
