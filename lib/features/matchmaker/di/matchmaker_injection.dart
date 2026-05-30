import 'package:qeran/core/di/injection_container.dart';

import '../dashboard/data/datasources/matchmaker_dashboard_remote_datasource.dart';
import '../dashboard/data/repositories/matchmaker_dashboard_repository_impl.dart';
import '../dashboard/domain/repositories/matchmaker_dashboard_repository.dart';
import '../dashboard/domain/usecases/get_matchmaker_dashboard_usecase.dart';
import '../dashboard/presentation/blocs/matchmaker_dashboard_cubit.dart';
import '../users/data/datasources/matchmaker_user_actions_remote_datasource.dart';
import '../users/data/datasources/matchmaker_user_profile_remote_datasource.dart';
import '../users/data/datasources/matchmaker_users_remote_datasource.dart';
import '../users/data/repositories/matchmaker_user_actions_repository_impl.dart';
import '../users/data/repositories/matchmaker_user_profile_repository_impl.dart';
import '../users/data/repositories/matchmaker_users_repository_impl.dart';
import '../users/domain/entities/matchmaker_users_list.dart';
import '../users/domain/repositories/matchmaker_user_actions_repository.dart';
import '../users/domain/repositories/matchmaker_user_profile_repository.dart';
import '../users/domain/repositories/matchmaker_users_repository.dart';
import '../users/domain/usecases/approve_user_usecase.dart';
import '../users/domain/usecases/fetch_matchmaker_user_profile_usecase.dart';
import '../users/domain/usecases/fetch_matchmaker_users_usecase.dart';
import '../users/domain/usecases/reject_user_usecase.dart';
import '../users/domain/usecases/request_image_user_usecase.dart';
import '../users/presentation/blocs/matchmaker_profile_detail_cubit.dart';
import '../users/presentation/blocs/matchmaker_user_actions_cubit.dart';
import '../users/presentation/blocs/matchmaker_users_list_cubit.dart';

/// Matchmaker (role=Moderator) feature DI registration.
///
/// Stateless services (data sources, repositories, use cases) are lazy
/// singletons; cubits with UI-lifecycle state are factories. Registered
/// per milestone:
///   • M2a — dashboard            ← here
///   • M2b — users lists
///   • M3  — compatibility-cases
///   • M4  — conversations + colleagues + matchmaker chat bootstrap
///   • M5  — explore
///   • M6  — notifications + account
///
/// Called from `core/di/injection_container.dart`.
Future<void> initMatchmakerDependencies() async {
  //! ── M2a · Dashboard ──────────────────────────────────────────────
  sl.registerLazySingleton<MatchmakerDashboardRemoteDataSource>(
    () => MatchmakerDashboardRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<MatchmakerDashboardRepository>(
    () => MatchmakerDashboardRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetMatchmakerDashboardUseCase(sl()));
  sl.registerFactory(
    () => MatchmakerDashboardCubit(getDashboard: sl()),
  );

  //! ── M2b · Users management ───────────────────────────────────────
  sl.registerLazySingleton<MatchmakerUsersRemoteDataSource>(
    () => MatchmakerUsersRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<MatchmakerUsersRepository>(
    () => MatchmakerUsersRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => FetchMatchmakerUsersUseCase(sl()));
  // One cubit per list — the caller passes which list via param1.
  sl.registerFactoryParam<MatchmakerUsersListCubit, MatchmakerUsersList, void>(
    (list, _) => MatchmakerUsersListCubit(list: list, fetchUsers: sl()),
  );

  //! ── M2c · User profile detail ────────────────────────────────────
  sl.registerLazySingleton<MatchmakerUserProfileRemoteDataSource>(
    () => MatchmakerUserProfileRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<MatchmakerUserProfileRepository>(
    () => MatchmakerUserProfileRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => FetchMatchmakerUserProfileUseCase(sl()));
  // One cubit per opened profile — the caller passes the userId via param1.
  sl.registerFactoryParam<MatchmakerProfileDetailCubit, String, void>(
    (userId, _) =>
        MatchmakerProfileDetailCubit(userId: userId, fetchProfile: sl()),
  );

  //! ── M2d · Profile actions (approve / reject / request-image) ──────
  sl.registerLazySingleton<MatchmakerUserActionsRemoteDataSource>(
    () => MatchmakerUserActionsRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<MatchmakerUserActionsRepository>(
    () => MatchmakerUserActionsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => ApproveUserUseCase(sl()));
  sl.registerLazySingleton(() => RejectUserUseCase(sl()));
  sl.registerLazySingleton(() => RequestImageUserUseCase(sl()));
  // One cubit per opened profile — the caller passes the userId via param1.
  sl.registerFactoryParam<MatchmakerUserActionsCubit, String, void>(
    (userId, _) => MatchmakerUserActionsCubit(
      userId: userId,
      approve: sl(),
      reject: sl(),
      requestImage: sl(),
    ),
  );
}
