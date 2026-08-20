import 'package:qeran/core/di/injection_container.dart';

import '../data/datasources/badges_remote_datasource.dart';
import '../data/repositories/badges_repository_impl.dart';
import '../domain/repositories/badges_repository.dart';
import '../domain/usecases/get_badges_usecase.dart';
import '../domain/usecases/mark_tab_seen_usecase.dart';
import '../presentation/blocs/badges_cubit.dart';

/// Bottom-nav + bell unread counts (`GET /api/badges`). Role-agnostic: the
/// server answers for whoever is signed in, so both shells share this module.
void initBadgesDependencies() {
  sl.registerLazySingleton<BadgesRemoteDataSource>(
    () => BadgesRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<BadgesRepository>(() => BadgesRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetBadgesUseCase(sl()));
  sl.registerLazySingleton(() => MarkTabSeenUseCase(sl()));
  // App-scoped: the counts outlive every screen that reads them, and both the
  // nav bar and the bell must see the same instance.
  sl.registerLazySingleton(
    () => BadgesCubit(getBadges: sl(), markTabSeen: sl()),
  );
}
