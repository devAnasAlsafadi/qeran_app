import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/community/presentation/screens/community_post_page.dart';
import 'package:qeran/features/community/presentation/widgets/post_screen/community_post_unavailable.dart';
import 'package:qeran/features/notifications/domain/entities/notification_item.dart';
import 'package:qeran/features/notifications/domain/entities/notification_type.dart';
import 'package:qeran/features/notifications/presentation/routing/notification_deep_link.dart';
import 'package:qeran/features/notifications/presentation/screens/notifications_screen.dart';

import '../../../community/fixtures/community_comment_fixtures.dart';
import '../../../community/fixtures/community_post_fixtures.dart';
import '../../../community/presentation/blocs/comments/comments_cubit_harness.dart';
import '../../../community/presentation/blocs/post/post_cubit_harness.dart';
import '../../../community/presentation/screens/post_screen_rig.dart';
import '../../../../core/shipped_strings_rig.dart';
import 'inbox_host.dart';

/// "New reply to your comment" on post 1, at reply 100 under comment 10.
const _reply = NotificationItem(
  id: 9,
  titleAr: 'ردّ جديد على تعليقك',
  titleEn: 'New reply to your comment',
  bodyAr: '',
  bodyEn: '',
  type: NotificationType.community,
  data: {
    'screen': 'community_post',
    'action': 'community_reply',
    'postId': '1',
    'commentId': '10',
    'replyId': '100',
  },
  createdAt: null,
);

/// A row tapped in the inbox opens its post over the inbox, at the comment
/// and reply it is about (H1, C8); a post that's gone takes the member back
/// to Community (Q12).
void main() {
  late PostHarness post;
  late CommentsHarness comments;
  Object? popped;
  setUpAll(initShippedStrings);
  setUp(() async {
    await sl.reset();
    popped = null;
    post = PostHarness();
    post.readAnswers(Right(testPost(commentCount: 2)));
    comments = CommentsHarness();
    comments.single(10, Right(testComment(id: 10, replyCount: 1)));
    comments.single(100, Right(testReply(id: 100)));
    comments.page(1, [testComment(id: 11)]);
    registerPostPage(post, comments);
  });
  tearDown(() async {
    AppSnackBar.debugReset();
    await post.dispose();
    await comments.dispose();
    await sl.reset();
  });

  /// The inbox, pushed over a first screen that keeps what it pops with.
  Future<void> openInbox(WidgetTester tester) async {
    await pumpInbox(
      tester,
      offline: false,
      items: [_reply],
      wrap: postScreenLayers,
      home: Builder(
        builder: (context) => GestureDetector(
          onTap: () async => popped = await Navigator.of(context).push<Object?>(
            MaterialPageRoute<Object?>(
              builder: (_) => const NotificationsScreen(),
            ),
          ),
          child: const Text('shell'),
        ),
      ),
    );
    await tester.tap(find.text('shell'));
    await tester.pumpAndSettle();
  }

  testWidgets('a reply notification opens its post over the inbox, at the '
      'reply; back returns to the inbox', (tester) async {
    await openInbox(tester);

    await tester.tap(find.text(_reply.titleEn));
    await tester.pumpAndSettle();

    expect(find.byType(CommunityPostPage), findsOneWidget);
    expect(find.byType(NotificationsScreen, skipOffstage: false), findsOne);
    verify(() => comments.getComment(10)).called(1);
    verify(() => comments.getComment(100)).called(1);

    Navigator.of(tester.element(find.byType(CommunityPostPage))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(popped, isNull);
  });

  testWidgets('its post gone: «العودة إلى المجتمع» leaves the inbox for the '
      'Community tab (Q12)', (tester) async {
    post.readAnswers(const Left(postNotFound));
    await openInbox(tester);
    await tester.tap(find.text(_reply.titleEn));
    await tester.pumpAndSettle();
    expect(find.byType(CommunityPostUnavailable), findsOneWidget);

    await tester.tap(find.text('community.back_to_community'));
    await tester.pumpAndSettle();

    expect(popped, const OpenCommunityTab());
    expect(find.byType(NotificationsScreen), findsNothing);
    expect(find.text('shell'), findsOneWidget);
  });
}
