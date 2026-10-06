import 'package:qeran/core/di/injection_container.dart';

import '../explore/data/datasources/matchmaker_explore_remote_datasource.dart';
import '../explore/data/repositories/matchmaker_explore_repository_impl.dart';
import '../explore/domain/repositories/matchmaker_explore_repository.dart';
import '../explore/domain/usecases/get_explore_filters_usecase.dart';
import '../explore/domain/usecases/get_explore_usecase.dart';
import '../explore/presentation/blocs/matchmaker_explore_cubit.dart';
import '../explore/presentation/blocs/share/matchmaker_share_cubit.dart';
import '../interests/data/datasources/matchmaker_interests_remote_datasource.dart';
import '../interests/data/repositories/matchmaker_interests_repository_impl.dart';
import '../interests/domain/repositories/matchmaker_interests_repository.dart';
import '../interests/domain/usecases/get_interest_archived_matches_usecase.dart';
import '../interests/domain/usecases/get_interest_likes_usecase.dart';
import '../interests/domain/usecases/get_interest_matches_usecase.dart';
import '../interests/presentation/blocs/matchmaker_interests_cubit.dart';

/// Explore and the interests mirror.
/// Called by [initMatchmakerDependencies].
void initMatchmakerExploreDependencies() {
  //! ── S4a · Explore (search + dynamic filters) ─────────────────────
  // Data/domain only here; the filter sheet + screen cubits land in S4b/S4c.
  // Filters reuse the discovery filter entity/model — same `/filters` shape.
  sl.registerLazySingleton<MatchmakerExploreRemoteDataSource>(
    () => MatchmakerExploreRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<MatchmakerExploreRepository>(
    () => MatchmakerExploreRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetExploreUseCase(sl()));
  sl.registerLazySingleton(() => GetExploreFiltersUseCase(sl()));
  // S4c · explore screen list cubit (one per mount). The filter-sheet cubit is
  // constructed inline by the sheet (it carries an initialSelections param).
  sl.registerFactory(() => MatchmakerExploreCubit(getExplore: sl()));
  // Share recipient picker — one per opened sheet; the caller passes the
  // browsed (shared) userId via param1. Recipients come from the existing
  // users-list use-case (approved lists only).
  sl.registerFactoryParam<MatchmakerShareCubit, String, void>(
    (sharedUserId, _) => MatchmakerShareCubit(
      sharedUserId: sharedUserId,
      fetchUsers: sl(),
      openChat: sl(),
      shareProfile: sl(),
    ),
  );

  //! ── M3f · Interests mirror (read-only) ───────────────────────────
  // Data/domain only here; the cubit (per userId) is registered in M3f-b.
  sl.registerLazySingleton<MatchmakerInterestsRemoteDataSource>(
    () => MatchmakerInterestsRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<MatchmakerInterestsRepository>(
    () => MatchmakerInterestsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetInterestLikesUseCase(sl()));
  sl.registerLazySingleton(() => GetInterestMatchesUseCase(sl()));
  sl.registerLazySingleton(() => GetInterestArchivedMatchesUseCase(sl()));
  // One cubit per opened interests screen — the caller passes the viewed
  // user's id via param1 (M3f-b).
  sl.registerFactoryParam<MatchmakerInterestsCubit, String, void>(
    (userId, _) => MatchmakerInterestsCubit(
      userId: userId,
      getLikes: sl(),
      getMatches: sl(),
      getArchivedMatches: sl(),
    ),
  );
}
