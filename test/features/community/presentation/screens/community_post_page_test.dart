import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/connectivity/connectivity_cubit.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/core/widgets/connectivity_banner_host.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/presentation/blocs/comments/community_comments_cubit.dart';
import 'package:qeran/features/community/presentation/blocs/composer/community_composer_cubit.dart';
import 'package:qeran/features/community/presentation/blocs/feed/community_feed_cubit.dart';
import 'package:qeran/features/community/presentation/blocs/post/community_post_cubit.dart';
import 'package:qeran/features/community/presentation/screens/community_feed_screen.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../../profile/presentation/fake_profile_gate.dart';
import '../../fixtures/community_comment_fixtures.dart';
import '../../fixtures/community_mock_harness.dart';
import '../../fixtures/community_post_fixtures.dart';
import '../blocs/comments/comments_cubit_harness.dart';
import '../blocs/feed/feed_cubit_harness.dart';
import '../blocs/post/post_cubit_harness.dart';
import 'post_screen_rig.dart';

/// The post page's cubits, built by the container as the app builds them,
/// over [post]'s and [comments]' scripted use cases.
void _register(PostHarness post, CommentsHarness comments) {
  sl.registerFactoryParam<CommunityPostCubit, int, CommunityPost?>(
    (postId, copy) => CommunityPostCubit(
      postId: postId,
      post: copy,
      getPost: post.getPost,
      setPostLike: post.setLike,
      watchChanges: post.watch,
    ),
  );
  sl.registerFactoryParam<CommunityCommentsCubit, int, void>(
    (postId, _) => CommunityCommentsCubit(
      postId: postId,
      getComments: comments.getComments,
      getReplies: comments.getReplies,
      setCommentLike: comments.setLike,
      createComment: comments.createComment,
      createReply: comments.createReply,
      getPost: comments.getPost,
    ),
  );
  sl.registerFactoryParam<CommunityComposerCubit, CommentSend, CommentRetry>(
    (send, retry) => composerOver(comments),
  );
}

/// The feed of [feed]'s cubit, under the app's own layers: the gate, the
/// connection — [offline] or not — and the toasts.
Future<void> _pumpFeed(
  WidgetTester tester,
  FeedHarness feed, {
  bool offline = false,
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 1000);
  addTearDown(tester.view.reset);
  addTearDown(AppSnackBar.debugReset);
  return pumpShippedStrings(
    tester,
    const Locale('en'),
    builder: (_, navigator) => MultiBlocProvider(
      providers: [
        BlocProvider<ProfileGateCubit>.value(
          value: FakeGate(ProfileStatus.visible),
        ),
        BlocProvider<ConnectivityCubit>(
          create: (_) => ConnectivityCubit(service: FakeConnectivity()),
        ),
      ],
      child: ConnectivityBannerHost(
        offline: offline,
        child: AppSnackBarHost(child: navigator!),
      ),
    ),
    child: BlocProvider<CommunityFeedCubit>.value(
      value: feed.cubit,
      child: const CommunityFeedView(),
    ),
  );
}

void main() {
  late FeedHarness feed;
  late PostHarness post;
  late CommentsHarness comments;
  setUpAll(initShippedStrings);
  setUp(() async {
    feed = FeedHarness();
    feed.page(1, [testPost()]);
    await feed.cubit.load();
    post = PostHarness();
    post.readAnswers(Right(testPost(commentCount: 1)));
    comments = CommentsHarness();
    comments.page(1, [testComment()]);
    _register(post, comments);
  });
  tearDown(() async {
    await sl.reset();
    await feed.dispose();
    await post.dispose();
    await comments.dispose();
  });

  testWidgets('a card\'s «ابدأ النقاش» opens its post: «المنشور», the post, '
      'its comments (S1)', (tester) async {
    await _pumpFeed(tester, feed);

    await tester.tap(find.text('Discuss'));
    await tester.pumpAndSettle();

    expect(find.text('Post'), findsOneWidget);
    expect(find.text(istikhara), findsOneWidget);
    expect(find.text(saraText), findsOneWidget);
    verify(() => post.getPost(1)).called(1);
  });

  testWidgets('C11: offline, the banner comes out under «المنشور», not over '
      'it', (tester) async {
    await _pumpFeed(tester, feed, offline: true);

    await tester.tap(find.text('Discuss'));
    await tester.pumpAndSettle();

    final banner = tester.getRect(
      find
          .ancestor(
            of: find.text('No Internet Connection'),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(banner.top, tester.getRect(find.byType(AppBar)).bottom);
  });

  testWidgets('C7: the post gone; «العودة إلى المجتمع» goes back to the '
      'feed', (tester) async {
    post.readAnswers(const Left(postNotFound));
    await _pumpFeed(tester, feed);

    await tester.tap(find.text('Discuss'));
    await tester.pumpAndSettle();
    expect(find.text('This post is no longer available'), findsOneWidget);

    await tester.tap(find.text('Back to Community'));
    await tester.pumpAndSettle();

    expect(find.text('Post'), findsNothing);
    expect(find.text('Community'), findsOneWidget);
  });
}
