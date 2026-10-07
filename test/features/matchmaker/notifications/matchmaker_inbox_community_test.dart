import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/features/community/domain/entities/community_viewer.dart';
import 'package:qeran/features/community/presentation/blocs/post_delete/post_delete_cubit.dart';
import 'package:qeran/features/community/presentation/screens/community_post_page.dart';
import 'package:qeran/features/matchmaker/community/presentation/screens/community_reports_page.dart';
import 'package:qeran/features/matchmaker/community/presentation/screens/matchmaker_community_screen.dart';
import 'package:qeran/features/matchmaker/notifications/domain/entities/matchmaker_notification.dart';
import 'package:qeran/features/matchmaker/notifications/presentation/screens/matchmaker_notifications_screen.dart';

import '../../../core/shipped_strings_rig.dart';
import '../../community/fixtures/community_comment_fixtures.dart';
import '../../community/fixtures/community_post_fixtures.dart';
import '../../community/presentation/blocs/comments/comments_cubit_harness.dart';
import '../../community/presentation/blocs/post/post_cubit_harness.dart';
import '../../community/presentation/screens/post_screen_rig.dart';
import '../community/community_screen_rig.dart';
import '../home/her_shell_fakes.dart';
import 'her_community_notifications.dart';

/// A Community row tapped in her inbox opens post 1 over the inbox, as her,
/// at the comment or reply it is about (C8, D31, D36); back is the inbox.
void main() {
  late PostHarness post;
  late CommentsHarness comments;
  setUpAll(initShippedStrings);
  setUp(() async {
    post = PostHarness()..readAnswers(Right(testPost(commentCount: 2)));
    comments = CommentsHarness()
      ..single(10, Right(testComment(id: 10, replyCount: 1)))
      ..single(100, Right(testReply(id: 100)))
      ..page(1, [testComment(id: 11)]);
    await registerHerInbox([herComment, herReply, herReport]);
    sl.registerSingleton<BadgesCubit>(ShellBadges());
  });
  tearDown(() async {
    AppSnackBar.debugReset();
    await post.dispose();
    await comments.dispose();
  });

  /// Her inbox, pushed over a first screen as the bell pushes it.
  Future<void> openInbox(WidgetTester tester, String language) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.reset);
    await pumpShippedStrings(
      tester,
      Locale(language),
      builder: (_, navigator) => postScreenLayers(navigator!),
      child: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const MatchmakerNotificationsScreen(),
            ),
          ),
          child: const Text('shell'),
        ),
      ),
    );
    await tester.tap(find.text('shell'));
    await tester.pumpAndSettle();
  }

  /// Whether each lands on reply 100 under comment 10, or on comment 10.
  final atReply = {herComment: false, herReply: true, herReport: true};

  for (final MapEntry(key: row, value: reply) in atReply.entries) {
    final action = row.data['action'];
    testWidgets('$action: post 1 over the inbox, as her, at its item; back '
        'is the inbox', (tester) async {
      registerPostPage(post, comments);
      await openInbox(tester, 'en');

      await tester.tap(find.text(row.titleEn));
      await tester.pumpAndSettle();

      final page = tester.widget<CommunityPostPage>(
        find.byType(CommunityPostPage),
      );
      expect((page.postId, page.viewer), (1, CommunityViewer.matchmaker));
      verify(() => comments.getComment(10)).called(1);
      if (reply) {
        verify(() => comments.getComment(100)).called(1);
      } else {
        verifyNever(() => comments.getComment(100));
      }
      expect(find.byType(CommunityReportsScreen), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(MatchmakerNotificationsScreen), findsOneWidget);
    });
  }

  testWidgets('its post gone: «العودة إلى المجتمع» opens her Community over '
      'the inbox; back from there is the inbox (Q12)', (tester) async {
    final community = CommunityScreenHarness();
    addTearDown(community.dispose);
    community.all.page(1, [testPost(id: 1)]);
    sl.unregister<PostDeleteCubit>();
    registerPostPage(post, comments);
    post.readAnswers(const Left(postNotFound));
    await openInbox(tester, 'ar');

    await tester.tap(find.text(herReply.titleAr));
    await tester.pumpAndSettle();
    await tester.tap(find.text('العودة إلى المجتمع'));
    await tester.pumpAndSettle();

    final screen = tester.widget<MatchmakerCommunityScreen>(
      find.byType(MatchmakerCommunityScreen),
    );
    expect(screen.initialTab, MatchmakerCommunityTab.all);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MatchmakerNotificationsScreen), findsOneWidget);
  });

  test('her inbox reads «Community» as her type', () {
    expect(
      MatchmakerNotificationType.fromWire('Community'),
      MatchmakerNotificationType.community,
    );
  });
}
