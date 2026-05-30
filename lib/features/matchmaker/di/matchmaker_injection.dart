import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/services/storage_service.dart';

import '../compatibility_cases/data/datasources/compatibility_cases_remote_datasource.dart';
import '../compatibility_cases/data/repositories/compatibility_cases_repository_impl.dart';
import '../compatibility_cases/domain/repositories/compatibility_cases_repository.dart';
import '../compatibility_cases/domain/usecases/get_compatibility_cases_usecase.dart';
import '../compatibility_cases/domain/usecases/update_formal_request_status_usecase.dart';
import '../compatibility_cases/presentation/blocs/matchmaker_case_status_cubit.dart';
import '../compatibility_cases/presentation/blocs/matchmaker_cases_list_cubit.dart';
import '../conversations/data/datasources/matchmaker_conversations_remote_datasource.dart';
import '../conversations/data/repositories/matchmaker_conversations_repository_impl.dart';
import '../conversations/domain/repositories/matchmaker_conversations_repository.dart';
import '../conversations/domain/usecases/get_user_conversations_usecase.dart';
import '../conversations/presentation/blocs/matchmaker_user_conversations_cubit.dart';
import '../dashboard/data/datasources/matchmaker_dashboard_remote_datasource.dart';
import '../dashboard/data/repositories/matchmaker_dashboard_repository_impl.dart';
import '../dashboard/domain/repositories/matchmaker_dashboard_repository.dart';
import '../dashboard/domain/usecases/get_matchmaker_dashboard_usecase.dart';
import '../dashboard/presentation/blocs/matchmaker_dashboard_cubit.dart';
import '../shared/data/datasources/matchmaker_realtime_signalr_service.dart';
import '../shared/domain/ports/matchmaker_realtime_port.dart';
import '../users/data/datasources/matchmaker_editable_answers_remote_datasource.dart';
import '../users/data/datasources/matchmaker_user_actions_remote_datasource.dart';
import '../users/data/datasources/matchmaker_user_profile_remote_datasource.dart';
import '../users/data/datasources/matchmaker_users_remote_datasource.dart';
import '../users/data/repositories/matchmaker_editable_answers_repository_impl.dart';
import '../users/data/repositories/matchmaker_user_actions_repository_impl.dart';
import '../users/data/repositories/matchmaker_user_profile_repository_impl.dart';
import '../users/data/repositories/matchmaker_users_repository_impl.dart';
import '../users/domain/entities/matchmaker_users_list.dart';
import '../users/domain/repositories/matchmaker_editable_answers_repository.dart';
import '../users/domain/repositories/matchmaker_user_actions_repository.dart';
import '../users/domain/repositories/matchmaker_user_profile_repository.dart';
import '../users/domain/repositories/matchmaker_users_repository.dart';
import '../users/domain/usecases/approve_user_usecase.dart';
import '../users/domain/usecases/fetch_matchmaker_user_profile_usecase.dart';
import '../users/domain/usecases/fetch_matchmaker_users_usecase.dart';
import '../users/domain/usecases/get_editable_answers_usecase.dart';
import '../users/domain/usecases/reject_user_usecase.dart';
import '../users/domain/usecases/request_image_user_usecase.dart';
import '../users/domain/usecases/update_text_answer_usecase.dart';
import '../users/presentation/blocs/matchmaker_answer_save_cubit.dart';
import '../users/presentation/blocs/matchmaker_editable_answers_cubit.dart';
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

  //! ── M2e · Editable text answers ──────────────────────────────────
  sl.registerLazySingleton<MatchmakerEditableAnswersRemoteDataSource>(
    () => MatchmakerEditableAnswersRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<MatchmakerEditableAnswersRepository>(
    () => MatchmakerEditableAnswersRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetEditableAnswersUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTextAnswerUseCase(sl()));
  sl.registerFactoryParam<MatchmakerEditableAnswersCubit, String, void>(
    (userId, _) => MatchmakerEditableAnswersCubit(
      userId: userId,
      getEditableAnswers: sl(),
    ),
  );
  sl.registerFactoryParam<MatchmakerAnswerSaveCubit, String, void>(
    (userId, _) =>
        MatchmakerAnswerSaveCubit(userId: userId, updateTextAnswer: sl()),
  );

  //! ── M3 · Compatibility cases ─────────────────────────────────────
  sl.registerLazySingleton<CompatibilityCasesRemoteDataSource>(
    () => CompatibilityCasesRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<CompatibilityCasesRepository>(
    () => CompatibilityCasesRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetCompatibilityCasesUseCase(sl()));
  sl.registerLazySingleton(() => UpdateFormalRequestStatusUseCase(sl()));
  sl.registerFactory(
    () => MatchmakerCasesListCubit(getCases: sl(), realtimePort: sl()),
  );
  // One status cubit per opened case — the caller passes the formalRequestId
  // via param1.
  sl.registerFactoryParam<MatchmakerCaseStatusCubit, int, void>(
    (formalRequestId, _) => MatchmakerCaseStatusCubit(
      formalRequestId: formalRequestId,
      update: sl(),
    ),
  );

  //! ── M4a · Conversations (with users) ─────────────────────────────
  sl.registerLazySingleton<MatchmakerConversationsRemoteDataSource>(
    () => MatchmakerConversationsRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<MatchmakerConversationsRepository>(
    () => MatchmakerConversationsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetUserConversationsUseCase(sl()));
  sl.registerFactory(
    () => MatchmakerUserConversationsCubit(getConversations: sl()),
  );

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
}
