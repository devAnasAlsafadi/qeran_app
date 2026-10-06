import 'package:flutter/foundation.dart';
import 'package:qeran/core/di/injection_container.dart';

import '../data/datasources/community_author_refusing_datasource.dart';
import '../data/datasources/community_author_remote_datasource.dart';
import '../data/datasources/community_author_remote_datasource_impl.dart';
import '../data/datasources/community_remote_datasource.dart';
import '../data/datasources/community_remote_datasource_impl.dart';
import '../data/repositories/community_author_repository_impl.dart';
import '../domain/repositories/community_author_repository.dart';
import '../domain/usecases/delete_community_post_usecase.dart';
import '../domain/usecases/dismiss_community_flag_usecase.dart';
import '../domain/usecases/get_community_flags_usecase.dart';
import '../domain/usecases/get_my_community_posts_usecase.dart';

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
  sl.registerLazySingleton(() => DeleteCommunityPostUseCase(sl()));
  sl.registerLazySingleton(() => GetCommunityFlagsUseCase(sl()));
  sl.registerLazySingleton(() => DismissCommunityFlagUseCase(sl()));
}

/// The live API — unless the member's side is the dev-flag mock, whose post
/// ids must never reach the live server (a delete could hit a real post).
CommunityAuthorRemoteDataSource _dataSource() {
  final live = CommunityAuthorRemoteDataSourceImpl(apiConsumer: sl());
  if (kReleaseMode) return live;
  final memberSide = sl<CommunityRemoteDataSource>();
  return memberSide is CommunityRemoteDataSourceImpl
      ? live
      : const CommunityAuthorRefusingDataSource();
}
