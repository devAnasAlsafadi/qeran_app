import 'package:flutter/foundation.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/core/state/account_scope.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/block/domain/repositories/community_member_blocker.dart';
import 'package:qeran/features/report/domain/repositories/content_reporter.dart';

import '../data/datasources/community_remote_datasource.dart';
import '../data/datasources/community_remote_datasource_impl.dart';
import '../data/datasources/mock/community_mock_dev_flag.dart';
import '../data/datasources/mock/community_mock_mode.dart';
import '../data/repositories/community_post_changes.dart';
import '../data/repositories/community_repository_impl.dart';
import '../domain/repositories/community_repository.dart';
import '../domain/usecases/accept_community_guidelines_usecase.dart';
import '../domain/usecases/block_community_member_usecase.dart';
import '../domain/usecases/create_community_comment_usecase.dart';
import '../domain/usecases/create_community_reply_usecase.dart';
import '../domain/usecases/delete_community_comment_usecase.dart';
import '../domain/usecases/get_comment_replies_usecase.dart';
import '../domain/usecases/get_community_comment_usecase.dart';
import '../domain/usecases/get_community_config_usecase.dart';
import '../domain/usecases/get_community_feed_usecase.dart';
import '../domain/usecases/get_community_guidelines_usecase.dart';
import '../domain/usecases/get_community_post_usecase.dart';
import '../domain/usecases/get_post_comments_usecase.dart';
import '../domain/usecases/report_community_content_usecase.dart';
import '../domain/usecases/set_comment_like_usecase.dart';
import '../domain/usecases/set_post_like_usecase.dart';
import '../domain/usecases/watch_community_post_changes_usecase.dart';
import '../domain/usecases/dismiss_community_flag_usecase.dart';
import '../domain/entities/community_landing.dart';
import '../domain/entities/community_post.dart';
import '../domain/entities/community_viewer.dart';
import '../presentation/blocs/comments/community_comments_cubit.dart';
import '../presentation/blocs/composer/community_composer_cubit.dart';
import '../presentation/blocs/composer/community_gate.dart';
import '../presentation/blocs/feed/community_feed_cubit.dart';
import '../presentation/blocs/guidelines/community_guidelines_cubit.dart';
import '../presentation/blocs/post/community_post_cubit.dart';
import '../presentation/video/community_video_player.dart';
import '../presentation/video/video_player_adapter.dart';
import 'community_author_injection.dart';

/// `--dart-define=COMMUNITY_MOCK=seeded|empty|errors|slow` (Q2). Read here
/// only, and only outside release builds.
const String _mockFlag = String.fromEnvironment('COMMUNITY_MOCK');

/// Wire Community into the global container. The repository is a lazy
/// singleton because it owns the app-lifetime `postChanges` stream and the
/// session's config; cubits are registered with their screens.
void initCommunityDependencies() {
  //! DataSource — the live API, or the dev-flag mock.
  sl.registerLazySingleton<CommunityRemoteDataSource>(_dataSource);

  //! Repository — and the post changes it shares with the author's.
  sl.registerLazySingleton(CommunityPostChanges.new);
  sl.registerLazySingleton<CommunityRepository>(
    () => sl<AccountScope>().hold<CommunityRepositoryImpl>(
      CommunityRepositoryImpl(sl(), changes: sl()),
      (repo) => repo.forgetAccount(),
    ),
  );

  //! UseCases
  sl.registerLazySingleton(() => GetCommunityFeedUseCase(sl()));
  sl.registerLazySingleton(() => GetCommunityPostUseCase(sl()));
  sl.registerLazySingleton(() => SetPostLikeUseCase(sl()));
  sl.registerLazySingleton(() => SetCommentLikeUseCase(sl()));
  sl.registerLazySingleton(() => GetPostCommentsUseCase(sl()));
  sl.registerLazySingleton(() => GetCommentRepliesUseCase(sl()));
  sl.registerLazySingleton(() => GetCommunityCommentUseCase(sl()));
  sl.registerLazySingleton(() => CreateCommunityCommentUseCase(sl()));
  sl.registerLazySingleton(() => CreateCommunityReplyUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCommunityCommentUseCase(sl()));
  sl.registerLazySingleton(() => GetCommunityConfigUseCase(sl()));
  sl.registerLazySingleton(() => GetCommunityGuidelinesUseCase(sl()));
  sl.registerLazySingleton(() => AcceptCommunityGuidelinesUseCase(sl()));
  // The report sheet's path for content (Q3): through Community's datasource,
  // so the dev-flag mock's ids never reach the real endpoint.
  sl.registerLazySingleton<ContentReporter>(
    () => ReportCommunityContentUseCase(sl()),
  );
  // The card's video player: `video_player`, swapped for a fake in tests.
  sl.registerLazySingleton<CommunityVideoPlayerFactory>(
    () => VideoPlayerAdapter.new,
  );
  // And the block cubit's, for a comment's author.
  sl.registerLazySingleton<CommunityMemberBlocker>(
    () => BlockCommunityMemberUseCase(sl()),
  );
  sl.registerLazySingleton(() => WatchCommunityPostChangesUseCase(sl()));

  sl.registerFactory(
    () => CommunityFeedCubit(
      getFeed: sl<GetCommunityFeedUseCase>().call,
      getPost: sl(),
      setPostLike: sl(),
      watchChanges: sl(),
    ),
  );
  // The post screen's pair: the post's id, and the feed's copy when there
  // is one.
  sl.registerFactoryParam<CommunityPostCubit, int, CommunityPost?>(
    (postId, post) => CommunityPostCubit(
      postId: postId,
      post: post,
      getPost: sl(),
      setPostLike: sl(),
      watchChanges: sl(),
    ),
  );
  // The composer sends through the comments cubit of its screen, and asks
  // the app's profile gate which steps the member still owes (D17, D7).
  sl.registerFactoryParam<CommunityComposerCubit, CommentSend, CommentRetry>(
    (send, retry) => CommunityComposerCubit(
      getConfig: sl(),
      send: send,
      retry: retry,
      owed: () => communityGateOf(sl<ProfileGateCubit>().state),
    ),
  );
  // Hers owes nothing: the member's steps aren't a matchmaker's (04 §3.4).
  sl.registerFactoryParam<CommunityComposerCubit, CommentSend, CommentRetry>(
    (send, retry) => CommunityComposerCubit(
      getConfig: sl(),
      send: send,
      retry: retry,
      owed: () => null,
    ),
    instanceName: CommunityViewer.matchmaker.name,
  );
  // The guidelines step tells the app's profile gate when they're accepted,
  // so the composer stops asking (D7).
  sl.registerFactory(
    () => CommunityGuidelinesCubit(
      getGuidelines: sl(),
      accept: sl(),
      onAccepted: sl<ProfileGateCubit>().markCommunityGuidelinesAccepted,
    ),
  );
  sl.registerFactoryParam<CommunityCommentsCubit, int, CommunityLanding?>(
    (postId, landing) => CommunityCommentsCubit(
      postId: postId,
      getComments: sl(),
      getReplies: sl(),
      setCommentLike: sl(),
      createComment: sl(),
      createReply: sl(),
      deleteComment: sl(),
      getPost: sl(),
      getComment: sl(),
      dismissFlag: (flagId) => sl<DismissCommunityFlagUseCase>()(flagId),
      onFlagCleared: _refreshBadges,
      landing: landing,
    ),
  );

  initCommunityAuthorDependencies();
}

CommunityRemoteDataSource _dataSource() {
  // `kReleaseMode` is a compile-time constant: in a release build everything
  // after this line is dead code and is compiled out — the mock and its seed
  // never ship.
  if (kReleaseMode) return CommunityRemoteDataSourceImpl(apiConsumer: sl());
  final mode = CommunityMockMode.fromFlag(_mockFlag);
  if (mode == null) return CommunityRemoteDataSourceImpl(apiConsumer: sl());
  return communityMockDevFlag(mode, connectivity: sl());
}

/// Her badges read again after she keeps or deletes a reported item (S16):
/// a backstop for the hub's `BadgeUpdated`, which needs a live connection.
void _refreshBadges() {
  if (sl.isRegistered<BadgesCubit>()) sl<BadgesCubit>().refresh();
}
