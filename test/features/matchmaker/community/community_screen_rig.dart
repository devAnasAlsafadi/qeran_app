import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/connectivity/connectivity_cubit.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/community/domain/entities/community_page.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/domain/usecases/get_my_community_posts_usecase.dart';
import 'package:qeran/features/community/presentation/blocs/feed/community_feed_cubit.dart';
import 'package:qeran/features/matchmaker/community/presentation/blocs/my_posts/my_posts_cubit.dart';

import '../../../core/shipped_strings_rig.dart';
import '../../auth/presentation/fake_session.dart';
import '../../community/fixtures/community_mock_harness.dart';
import '../../community/presentation/blocs/feed/feed_cubit_harness.dart';

class _MockGetMyPosts extends Mock implements GetMyCommunityPostsUseCase {}

/// Her Community screen's two lists over scripted sources: «كل المنشورات»
/// reads [all]'s use cases; «منشوراتي» is a [MyPostsCubit] over [getMyPosts],
/// on [all]'s change stream. Each «منشوراتي» opening counts in [seen]. The
/// screen gets fresh cubits and closes them itself; [mine] is one for the
/// cubit's own tests.
class CommunityScreenHarness {
  CommunityScreenHarness() {
    sl.registerFactory<CommunityFeedCubit>(
      () => CommunityFeedCubit(
        getFeed: all.getFeed.call,
        getPost: all.getPost,
        setPostLike: all.setLike,
        watchChanges: all.watch,
      ),
    );
    sl.registerFactory<MyPostsCubit>(_newMine);
  }

  final all = FeedHarness();
  final getMyPosts = _MockGetMyPosts();
  int seen = 0;
  MyPostsCubit? _mine;

  MyPostsCubit get mine => _mine ??= _newMine();

  MyPostsCubit _newMine() => MyPostsCubit(
    getMyPosts: getMyPosts,
    getPost: all.getPost,
    setPostLike: all.setLike,
    watchChanges: all.watch,
    markCommentsSeen: () async => seen++,
  );

  /// Her posts' [page] answers with [posts].
  void myPage(int page, List<CommunityPost> posts, {int totalPages = 1}) =>
      when(() => getMyPosts(page: page)).thenAnswer(
        (_) async => Right(
          CommunityPage(
            items: posts,
            pageNumber: page,
            pageSize: 20,
            totalCount: posts.length,
            totalPages: totalPages,
          ),
        ),
      );

  /// Her posts' first page fails.
  void myPageFails() => when(() => getMyPosts(page: 1)).thenAnswer(
    (_) async =>
        const Left<Failure, CommunityPage<CommunityPost>>(OfflineFailure()),
  );

  Future<void> dispose() async {
    await _mine?.close();
    await all.dispose();
    await sl.reset();
  }
}

/// [child] as her app holds it: signed in as her, the connection and the
/// toasts above the navigator, in [locale] on a phone.
Future<void> pumpHerApp(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  bool settle = true,
}) {
  signInForTest();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 900);
  addTearDown(tester.view.reset);
  addTearDown(AppSnackBar.debugReset);
  return pumpShippedStrings(
    tester,
    locale,
    settle: settle,
    builder: (_, navigator) => BlocProvider<ConnectivityCubit>(
      create: (_) => ConnectivityCubit(service: FakeConnectivity()),
      child: AppSnackBarHost(child: navigator!),
    ),
    child: child,
  );
}
