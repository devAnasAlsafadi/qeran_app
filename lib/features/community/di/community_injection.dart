import 'package:flutter/foundation.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';

import '../data/datasources/community_remote_datasource.dart';
import '../data/datasources/community_remote_datasource_impl.dart';
import '../data/datasources/mock/community_mock_datasource.dart';
import '../data/datasources/mock/community_mock_mode.dart';
import '../data/repositories/community_repository_impl.dart';
import '../domain/repositories/community_repository.dart';
import '../domain/usecases/accept_community_guidelines_usecase.dart';
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
import '../domain/usecases/set_comment_like_usecase.dart';
import '../domain/usecases/set_post_like_usecase.dart';
import '../domain/usecases/watch_community_post_changes_usecase.dart';
import '../domain/entities/community_post.dart';
import '../presentation/blocs/comments/community_comments_cubit.dart';
import '../presentation/blocs/composer/community_composer_cubit.dart';
import '../presentation/blocs/feed/community_feed_cubit.dart';
import '../presentation/blocs/guidelines/community_guidelines_cubit.dart';
import '../presentation/blocs/post/community_post_cubit.dart';

/// `--dart-define=COMMUNITY_MOCK=seeded|empty|errors|slow` (Q2). Read here
/// only, and only outside release builds.
const String _mockFlag = String.fromEnvironment('COMMUNITY_MOCK');

/// Wire Community into the global container. The repository is a lazy
/// singleton because it owns the app-lifetime `postChanges` stream and the
/// session's config; cubits are registered with their screens.
void initCommunityDependencies() {
  //! DataSource — the live API, or the dev-flag mock.
  sl.registerLazySingleton<CommunityRemoteDataSource>(_dataSource);

  //! Repository
  sl.registerLazySingleton<CommunityRepository>(
    () => CommunityRepositoryImpl(sl()),
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
  sl.registerLazySingleton(() => WatchCommunityPostChangesUseCase(sl()));

  sl.registerFactory(
    () => CommunityFeedCubit(
      getFeed: sl(),
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
  // The composer sends through the comments cubit of its screen.
  sl.registerFactoryParam<CommunityComposerCubit, CommentSend, CommentRetry>(
    (send, retry) =>
        CommunityComposerCubit(getConfig: sl(), send: send, retry: retry),
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
  sl.registerFactoryParam<CommunityCommentsCubit, int, void>(
    (postId, _) => CommunityCommentsCubit(
      postId: postId,
      getComments: sl(),
      getReplies: sl(),
      setCommentLike: sl(),
      createComment: sl(),
      createReply: sl(),
      getPost: sl(),
    ),
  );
}

CommunityRemoteDataSource _dataSource() {
  // `kReleaseMode` is a compile-time constant: in a release build everything
  // after this line is dead code and is compiled out — the mock and its seed
  // never ship.
  if (kReleaseMode) return CommunityRemoteDataSourceImpl(apiConsumer: sl());
  final mode = CommunityMockMode.fromFlag(_mockFlag);
  if (mode == null) return CommunityRemoteDataSourceImpl(apiConsumer: sl());
  return CommunityMockDataSource.devFlag(mode, connectivity: sl());
}
