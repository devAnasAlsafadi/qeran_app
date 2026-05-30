import 'package:qeran/core/di/injection_container.dart';

import '../dashboard/data/datasources/matchmaker_dashboard_remote_datasource.dart';
import '../dashboard/data/repositories/matchmaker_dashboard_repository_impl.dart';
import '../dashboard/domain/repositories/matchmaker_dashboard_repository.dart';
import '../dashboard/domain/usecases/get_matchmaker_dashboard_usecase.dart';
import '../dashboard/presentation/blocs/matchmaker_dashboard_cubit.dart';

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
}
