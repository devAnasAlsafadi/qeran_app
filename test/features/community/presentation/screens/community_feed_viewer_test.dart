import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/connectivity/connectivity_cubit.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/community/domain/entities/community_like_state.dart';
import 'package:qeran/features/community/domain/entities/community_viewer.dart';
import 'package:qeran/features/community/presentation/blocs/feed/community_feed_cubit.dart';
import 'package:qeran/features/community/presentation/screens/community_feed_screen.dart';
import 'package:qeran/features/community/presentation/screens/community_post_page.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../../auth/presentation/fake_session.dart';
import '../../../profile/presentation/fake_profile_gate.dart';
import '../../fixtures/community_comment_fixtures.dart';
import '../../fixtures/community_mock_harness.dart';
import '../../fixtures/community_post_fixtures.dart';
import '../blocs/comments/comments_cubit_harness.dart';
import '../blocs/feed/feed_cubit_harness.dart';
import '../blocs/post/post_cubit_harness.dart';
import 'post_screen_rig.dart';

/// Her «كل المنشورات»: the shared feed as a matchmaker sees it, under a gate
/// that fails the test if anything reads it, with the app's layers above the
/// navigator so a post opens.
Future<void> _pumpHers(
  WidgetTester tester,
  FeedHarness feed, {
  Locale locale = const Locale('en'),
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 1200);
  addTearDown(tester.view.reset);
  addTearDown(AppSnackBar.debugReset);
  return pumpShippedStrings(
    tester,
    locale,
    builder: (_, navigator) => MultiBlocProvider(
      providers: [
        BlocProvider<ProfileGateCubit>.value(value: UnreadGate()),
        BlocProvider<ConnectivityCubit>(
          create: (_) => ConnectivityCubit(service: FakeConnectivity()),
        ),
      ],
      child: AppSnackBarHost(child: navigator!),
    ),
    child: BlocProvider<CommunityFeedCubit>.value(
      value: feed.cubit,
      child: const CommunityFeedView(
        viewer: CommunityViewer.matchmaker,
        bottomClearance: 96,
      ),
    ),
  );
}

void main() {
  late FeedHarness feed;
  setUpAll(initShippedStrings);
  setUp(() => feed = FeedHarness());
  tearDown(() async {
    await sl.reset();
    await feed.dispose();
  });

  for (final (locale, title, subtitle) in [
    (const Locale('ar'), 'المجتمع', 'إرشادات تنشرها خطّابات قِران'),
    (
      const Locale('en'),
      'Community',
      'Guidance published by Qeran’s matchmakers',
    ),
  ]) {
    testWidgets('${locale.languageCode}: no title, subtitle or gate notice, '
        'and her likes are never read-only (K18)', (tester) async {
      signInForTest();
      feed.page(1, [testPost()]);
      feed.likeAnswers(
        1,
        const Right(CommunityLikeState(likeCount: 1, likedByMe: true)),
      );
      await feed.cubit.load();
      await _pumpHers(tester, feed, locale: locale);

      expect(find.text(title), findsNothing);
      expect(find.text(subtitle), findsNothing);
      await tester.tap(
        find.text(locale.languageCode == 'ar' ? 'إعجاب' : 'Like'),
      );
      await tester.pump();

      verify(() => feed.setLike(1, liked: true)).called(1);
    });
  }

  testWidgets('ar: her error state speaks to her in the feminine (Q9)', (
    tester,
  ) async {
    signInForTest();
    feed.pageFails(1);
    await feed.cubit.load();
    await _pumpHers(tester, feed, locale: const Locale('ar'));

    expect(
      find.text('تحقّقي من اتصالك بالإنترنت وحاولي مرة أخرى.'),
      findsOneWidget,
    );
    expect(find.text('حاولي مرة أخرى'), findsOneWidget);
  });

  testWidgets('a post opens as her: her composer, in the feminine', (
    tester,
  ) async {
    signInForTest();
    feed.page(1, [testPost()]);
    await feed.cubit.load();
    final post = PostHarness();
    post.readAnswers(Right(testPost(commentCount: 1)));
    final comments = CommentsHarness();
    comments.page(1, [testComment()]);
    registerPostPage(post, comments);
    addTearDown(() async {
      await post.dispose();
      await comments.dispose();
    });
    await _pumpHers(tester, feed, locale: const Locale('ar'));

    // Her «ابدأ النقاش» is in the feminine too.
    await tester.tap(find.text('ابدئي النقاش'));
    await tester.pumpAndSettle();

    final page = tester.widget<CommunityPostPage>(
      find.byType(CommunityPostPage),
    );
    expect(page.viewer, CommunityViewer.matchmaker);
    expect(find.text('اكتبي تعليقاً…'), findsOneWidget);
  });
}
