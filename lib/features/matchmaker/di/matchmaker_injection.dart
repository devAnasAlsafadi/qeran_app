import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/services/storage_service.dart';

import '../dashboard/data/datasources/matchmaker_dashboard_remote_datasource.dart';
import '../dashboard/data/repositories/matchmaker_dashboard_repository_impl.dart';
import '../dashboard/domain/repositories/matchmaker_dashboard_repository.dart';
import '../dashboard/domain/usecases/get_matchmaker_dashboard_usecase.dart';
import '../dashboard/presentation/blocs/matchmaker_dashboard_cubit.dart';
import '../shared/data/datasources/matchmaker_realtime_signalr_service.dart';
import '../shared/domain/ports/matchmaker_realtime_port.dart';
import 'matchmaker_users_injection.dart';
import 'matchmaker_cases_injection.dart';
import 'matchmaker_conversations_injection.dart';
import 'matchmaker_explore_injection.dart';
import 'matchmaker_account_injection.dart';

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
  sl.registerFactory(() => MatchmakerDashboardCubit(getDashboard: sl()));

  //! ── M4c-1 · App-wide realtime (matchmaker-owned, isolated) ───────
  // A SEPARATE SignalR connection from the user-side chat realtime port:
  // same hub + auth, but its own HubConnection / streams / lifecycle, so
  // chat behavior is untouched. The shell owns connect/disconnect; the
  // cases-list cubit consumes `caseUpdates`. Reuses the same secure-
  // storage token source the chat connection uses (no new token plumbing).
  sl.registerLazySingleton<MatchmakerRealtimePort>(
    () => MatchmakerRealtimeSignalRService(
      accessTokenProvider: () =>
          sl<StorageService>().get<String>(StorageKeys.token),
    ),
  );

  //! ── The rest, one file each ─────────────────────────────────────
  initMatchmakerUsersDependencies();
  initMatchmakerCasesDependencies();
  initMatchmakerConversationsDependencies();
  initMatchmakerExploreDependencies();
  initMatchmakerAccountDependencies();
}
