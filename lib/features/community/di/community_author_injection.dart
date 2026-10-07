import 'package:flutter/foundation.dart';
import 'package:qeran/core/di/injection_container.dart';

import '../data/datasources/community_author_refusing_datasource.dart';
import '../data/datasources/community_author_remote_datasource.dart';
import '../data/datasources/community_author_remote_datasource_impl.dart';
import '../data/datasources/community_remote_datasource.dart';
import '../data/datasources/community_remote_datasource_impl.dart';
import '../data/media/file_media_inspector.dart';
import '../data/repositories/community_author_repository_impl.dart';
import '../domain/ports/media_inspector.dart';
import '../domain/repositories/community_author_repository.dart';
import '../domain/usecases/create_community_post_usecase.dart';
import '../domain/usecases/delete_community_post_usecase.dart';
import '../domain/usecases/dismiss_community_flag_usecase.dart';
import '../domain/usecases/get_community_flags_usecase.dart';
import '../domain/usecases/get_my_community_posts_usecase.dart';
import '../domain/usecases/inspect_picked_image_usecase.dart';
import '../presentation/blocs/post_delete/post_delete_cubit.dart';

/// The post author's side of Community (the matchmaker app): her posts, a
/// post's delete, the flags. Registered with the member's side, which owns
/// the post-change stream both repositories speak on; nothing here is built
/// until her screens ask.
void initCommunityAuthorDependencies() {
  sl.registerLazySingleton<CommunityAuthorRemoteDataSource>(_dataSource);
  sl.registerLazySingleton<CommunityAuthorRepository>(
    () => CommunityAuthorRepositoryImpl(sl(), changes: sl()),
  );

  sl.registerLazySingleton(() => GetMyCommunityPostsUseCase(sl()));
  sl.registerLazySingleton(() => CreateCommunityPostUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCommunityPostUseCase(sl()));
  sl.registerLazySingleton(() => GetCommunityFlagsUseCase(sl()));
  sl.registerLazySingleton(() => DismissCommunityFlagUseCase(sl()));

  // Her composer's media: what a picked file really is.
  sl.registerLazySingleton<MediaInspector>(() => const FileMediaInspector());
  sl.registerLazySingleton(() => InspectPickedImageUseCase(sl()));

  // Deleting her post, on her lists and on its own screen.
  sl.registerFactory(() => PostDeleteCubit(deletePost: sl()));
}

/// The live API — unless the member's side is the dev-flag mock, whose post
/// ids must never reach the live server (a delete could hit a real post).
CommunityAuthorRemoteDataSource _dataSource() {
  final mock =
      !kReleaseMode &&
      sl<CommunityRemoteDataSource>() is! CommunityRemoteDataSourceImpl;
  if (mock) return const CommunityAuthorRefusingDataSource();
  return CommunityAuthorRemoteDataSourceImpl(apiConsumer: sl(), uploader: sl());
}
