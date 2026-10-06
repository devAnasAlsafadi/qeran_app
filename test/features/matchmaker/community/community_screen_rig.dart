import 'dart:async';

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
import 'package:qeran/features/community/domain/entities/community_post_change.dart';
import 'package:qeran/features/community/domain/usecases/delete_community_post_usecase.dart';
import 'package:qeran/features/community/domain/usecases/get_my_community_posts_usecase.dart';
import 'package:qeran/features/community/presentation/blocs/feed/community_feed_cubit.dart';
import 'package:qeran/features/community/presentation/blocs/post_delete/post_delete_cubit.dart';
import 'package:qeran/features/matchmaker/community/presentation/blocs/my_posts/my_posts_cubit.dart';
import 'package:qeran/features/matchmaker/shared/domain/entities/community_post_status_change.dart';

import '../../../core/shipped_strings_rig.dart';
import '../../auth/presentation/fake_session.dart';
import '../../community/fixtures/community_mock_harness.dart';
import '../../community/presentation/blocs/feed/feed_cubit_harness.dart';

class _MockGetMyPosts extends Mock implements GetMyCommunityPostsUseCase {}

class _MockDeletePost extends Mock implements DeleteCommunityPostUseCase {}

/// A timer the test fires by hand; cancelling it stops the ticks.
class _FakeTimer implements Timer {
  _FakeTimer({this.onCancel});

  final void Function()? onCancel;
  bool _active = true;

  @override
  void cancel() {
    _active = false;
    onCancel?.call();
  }

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

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
    sl.registerFactory<PostDeleteCubit>(
      () => PostDeleteCubit(deletePost: deletePost),
    );
  }

  final all = FeedHarness();
  final getMyPosts = _MockGetMyPosts();
  final deletePost = _MockDeletePost();
  int seen = 0;
  MyPostsCubit? _mine;

  MyPostsCubit get mine => _mine ??= _newMine();

  /// The hub's `CommunityPostStatusChanged`, as her port would hand it on.
  final statusChanges = StreamController<CommunityPostStatusChange>.broadcast();

  /// The poll's timer, driven by hand: [tick] fires it.
  final ticks = <void Function(Timer)>[];

  void tick() {
    for (final fire in List.of(ticks)) {
      fire(_FakeTimer());
    }
  }

  MyPostsCubit _newMine() => MyPostsCubit(
    getMyPosts: getMyPosts,
    getPost: all.getPost,
    setPostLike: all.setLike,
    watchChanges: all.watch,
    markCommentsSeen: () async => seen++,
    statusChanges: statusChanges.stream,
    startTimer: (every, fire) {
      ticks.add(fire);
      return _FakeTimer(onCancel: () => ticks.remove(fire));
    },
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

  /// Deleting [postId] succeeds — and, as the repository does, announces it
  /// gone — or fails offline.
  void deleteAnswers(int postId, {bool ok = true}) =>
      when(() => deletePost(postId)).thenAnswer((_) async {
        if (!ok) return const Left(OfflineFailure());
        all.changes.add(CommunityPostGone(postId));
        return const Right(unit);
      });

  /// Her posts' first page fails.
  void myPageFails() => when(() => getMyPosts(page: 1)).thenAnswer(
    (_) async =>
        const Left<Failure, CommunityPage<CommunityPost>>(OfflineFailure()),
  );

  Future<void> dispose() async {
    await _mine?.close();
    await statusChanges.close();
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
