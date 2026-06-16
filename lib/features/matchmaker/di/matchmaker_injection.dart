import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/services/storage_service.dart';

import '../account/data/datasources/matchmaker_account_remote_datasource.dart';
import '../account/data/repositories/matchmaker_account_repository_impl.dart';
import '../account/domain/repositories/matchmaker_account_repository.dart';
import '../account/domain/usecases/change_password_usecase.dart';
import '../account/domain/usecases/deactivate_account_usecase.dart';
import '../account/domain/usecases/get_me_usecase.dart';
import '../account/domain/usecases/update_name_usecase.dart';
import '../account/domain/usecases/upload_account_photo_usecase.dart';
import '../account/presentation/blocs/matchmaker_account_cubit.dart';
import '../colleagues/data/datasources/matchmaker_colleagues_remote_datasource.dart';
import '../colleagues/data/repositories/matchmaker_colleagues_repository_impl.dart';
import '../colleagues/domain/repositories/matchmaker_colleagues_repository.dart';
import '../colleagues/domain/usecases/get_colleague_conversations_usecase.dart';
import '../colleagues/domain/usecases/get_colleagues_usecase.dart';
import '../colleagues/domain/usecases/open_colleague_chat_usecase.dart';
import '../colleagues/presentation/blocs/matchmaker_colleague_conversations_cubit.dart';
import '../colleagues/presentation/blocs/matchmaker_colleague_open_chat_cubit.dart';
import '../colleagues/presentation/blocs/matchmaker_colleagues_directory_cubit.dart';
import '../compatibility_cases/data/datasources/case_note_remote_datasource.dart';
import '../compatibility_cases/data/datasources/compatibility_cases_remote_datasource.dart';
import '../compatibility_cases/data/repositories/case_note_repository_impl.dart';
import '../compatibility_cases/data/repositories/compatibility_cases_repository_impl.dart';
import '../compatibility_cases/domain/repositories/case_note_repository.dart';
import '../compatibility_cases/domain/repositories/compatibility_cases_repository.dart';
import '../compatibility_cases/domain/usecases/delete_case_note_usecase.dart';
import '../compatibility_cases/domain/usecases/get_case_note_usecase.dart';
import '../compatibility_cases/domain/usecases/get_compatibility_cases_usecase.dart';
import '../compatibility_cases/domain/usecases/save_case_note_usecase.dart';
import '../compatibility_cases/domain/usecases/update_formal_request_status_usecase.dart';
import '../compatibility_cases/presentation/blocs/case_note/case_note_cubit.dart';
import '../compatibility_cases/presentation/blocs/matchmaker_case_status_cubit.dart';
import '../compatibility_cases/presentation/blocs/matchmaker_cases_list_cubit.dart';
import '../conversations/data/datasources/matchmaker_conversations_remote_datasource.dart';
import '../conversations/data/repositories/matchmaker_conversations_repository_impl.dart';
import '../conversations/domain/repositories/matchmaker_conversations_repository.dart';
import '../conversations/domain/usecases/get_user_conversations_usecase.dart';
import '../conversations/domain/usecases/open_user_chat_usecase.dart';
import '../conversations/presentation/blocs/matchmaker_open_chat_cubit.dart';
import '../conversations/presentation/blocs/matchmaker_user_conversations_cubit.dart';
import '../explore/data/datasources/matchmaker_explore_remote_datasource.dart';
import '../explore/data/repositories/matchmaker_explore_repository_impl.dart';
import '../explore/domain/repositories/matchmaker_explore_repository.dart';
import '../explore/domain/usecases/get_explore_filters_usecase.dart';
import '../explore/domain/usecases/get_explore_usecase.dart';
import '../explore/presentation/blocs/matchmaker_explore_cubit.dart';
import '../dashboard/data/datasources/matchmaker_dashboard_remote_datasource.dart';
import '../dashboard/data/repositories/matchmaker_dashboard_repository_impl.dart';
import '../dashboard/domain/repositories/matchmaker_dashboard_repository.dart';
import '../dashboard/domain/usecases/get_matchmaker_dashboard_usecase.dart';
import '../dashboard/presentation/blocs/matchmaker_dashboard_cubit.dart';
import '../interests/data/datasources/matchmaker_interests_remote_datasource.dart';
import '../interests/data/repositories/matchmaker_interests_repository_impl.dart';
import '../interests/domain/repositories/matchmaker_interests_repository.dart';
import '../interests/domain/usecases/get_interest_archived_matches_usecase.dart';
import '../interests/domain/usecases/get_interest_likes_usecase.dart';
import '../interests/domain/usecases/get_interest_matches_usecase.dart';
import '../interests/presentation/blocs/matchmaker_interests_cubit.dart';
import '../notifications/data/datasources/matchmaker_notifications_remote_datasource.dart';
import '../notifications/data/repositories/matchmaker_notifications_repository_impl.dart';
import '../notifications/domain/repositories/matchmaker_notifications_repository.dart';
import '../notifications/domain/usecases/get_notification_count_usecase.dart';
import '../notifications/domain/usecases/get_notifications_usecase.dart';
import '../notifications/presentation/blocs/matchmaker_notification_badge_cubit.dart';
import '../notifications/presentation/blocs/matchmaker_notifications_cubit.dart';
import '../shared/data/datasources/matchmaker_realtime_signalr_service.dart';
import '../shared/domain/ports/matchmaker_realtime_port.dart';
import '../users/data/datasources/matchmaker_editable_answers_remote_datasource.dart';
import '../users/data/datasources/matchmaker_user_actions_remote_datasource.dart';
import '../users/data/datasources/matchmaker_user_notes_remote_datasource.dart';
import '../users/data/datasources/matchmaker_user_profile_remote_datasource.dart';
import '../users/data/datasources/matchmaker_users_remote_datasource.dart';
import '../users/data/repositories/matchmaker_editable_answers_repository_impl.dart';
import '../users/data/repositories/matchmaker_user_actions_repository_impl.dart';
import '../users/data/repositories/matchmaker_user_notes_repository_impl.dart';
import '../users/data/repositories/matchmaker_user_profile_repository_impl.dart';
import '../users/data/repositories/matchmaker_users_repository_impl.dart';
import '../users/domain/entities/matchmaker_users_list.dart';
import '../users/domain/repositories/matchmaker_editable_answers_repository.dart';
import '../users/domain/repositories/matchmaker_user_actions_repository.dart';
import '../users/domain/repositories/matchmaker_user_notes_repository.dart';
import '../users/domain/repositories/matchmaker_user_profile_repository.dart';
import '../users/domain/repositories/matchmaker_users_repository.dart';
import '../users/domain/usecases/approve_user_usecase.dart';
import '../users/domain/usecases/delete_user_note_usecase.dart';
import '../users/domain/usecases/fetch_matchmaker_user_profile_usecase.dart';
import '../users/domain/usecases/fetch_matchmaker_users_usecase.dart';
import '../users/domain/usecases/fetch_subscription_plans_usecase.dart';
import '../users/domain/usecases/get_user_note_usecase.dart';
import '../users/domain/usecases/reject_user_usecase.dart';
import '../users/domain/usecases/request_image_user_usecase.dart';
import '../users/domain/usecases/save_user_note_usecase.dart';
import '../users/domain/usecases/update_text_answer_usecase.dart';
import '../users/presentation/blocs/matchmaker_answer_save_cubit.dart';
import '../users/presentation/blocs/matchmaker_profile_detail_cubit.dart';
import '../users/presentation/blocs/matchmaker_user_actions_cubit.dart';
import '../users/presentation/blocs/matchmaker_user_notes_cubit.dart';
import '../users/presentation/blocs/matchmaker_users_list_cubit.dart';
import '../users/presentation/blocs/subscription_plans_cubit.dart';

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
  // The dynamic plan list backing the مشتركون filter rail (Step B cubit).
  sl.registerLazySingleton(() => FetchSubscriptionPlansUseCase(sl()));
  // Plan-filter rail cubit — one per subscribed-list mount (Step C provides it
  // above the rail + list so both share the selection). Factory, not singleton:
  // the BlocProvider owns + closes it, and selection resets on remount.
  sl.registerFactory(() => SubscriptionPlansCubit(fetchPlans: sl()));
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

  //! ── M2e / PV3 · Text-answer save (inline editor) ─────────────────
  // Read-side listing removed with the standalone screen (PV4); the save
  // stack powers the inline profile editor.
  sl.registerLazySingleton<MatchmakerEditableAnswersRemoteDataSource>(
    () => MatchmakerEditableAnswersRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<MatchmakerEditableAnswersRepository>(
    () => MatchmakerEditableAnswersRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => UpdateTextAnswerUseCase(sl()));
  sl.registerFactoryParam<MatchmakerAnswerSaveCubit, String, void>(
    (userId, _) =>
        MatchmakerAnswerSaveCubit(userId: userId, updateTextAnswer: sl()),
  );

  //! ── M3d · User notes (view / save / delete) ──────────────────────
  sl.registerLazySingleton<MatchmakerUserNotesRemoteDataSource>(
    () => MatchmakerUserNotesRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<MatchmakerUserNotesRepository>(
    () => MatchmakerUserNotesRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetUserNoteUseCase(sl()));
  sl.registerLazySingleton(() => SaveUserNoteUseCase(sl()));
  sl.registerLazySingleton(() => DeleteUserNoteUseCase(sl()));
  // One cubit per opened notes sheet — the caller passes the userId via param1.
  sl.registerFactoryParam<MatchmakerUserNotesCubit, String, void>(
    (userId, _) => MatchmakerUserNotesCubit(
      userId: userId,
      getNote: sl(),
      saveNote: sl(),
      deleteNote: sl(),
    ),
  );

  //! ── Compatibility-case notes (view / save / delete) ──────────────
  sl.registerLazySingleton<CaseNoteRemoteDataSource>(
    () => CaseNoteRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<CaseNoteRepository>(
    () => CaseNoteRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetCaseNoteUseCase(sl()));
  sl.registerLazySingleton(() => SaveCaseNoteUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCaseNoteUseCase(sl()));
  // One cubit per opened notes sheet — the caller passes the caseId via param1.
  sl.registerFactoryParam<CaseNoteCubit, int, void>(
    (caseId, _) => CaseNoteCubit(
      caseId: caseId,
      getNote: sl(),
      saveNote: sl(),
      deleteNote: sl(),
    ),
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
  sl.registerLazySingleton(() => OpenUserChatUseCase(sl()));
  // One open-chat cubit per user list (M3c) — resolves the lazy
  // /matchmaker/users/{id}/chat conversation, then the host navigates with it.
  sl.registerFactory(() => MatchmakerOpenChatCubit(openUserChat: sl()));
  // One cubit per conversations tab mount — the caller passes the current
  // user's id (from UserSessionCubit) via param1 so self-sent live messages
  // don't bump unread. The realtime port (4c-1) is reused.
  sl.registerFactoryParam<MatchmakerUserConversationsCubit, String, void>(
    (myUserId, _) => MatchmakerUserConversationsCubit(
      getConversations: sl(),
      realtimePort: sl(),
      myUserId: myUserId,
    ),
  );

  //! ── S2a · Colleagues (directory + colleague conversations) ───────
  // Data/domain only here; the colleague-conversations list + directory UI
  // and their cubits are wired in S2b/S2c. The colleague chat reuses the
  // shared MatchmakerUserChatScreen (the MatchmakerConversation entity is
  // generic), and the "start chat" action reuses the open-chat→navigate host.
  sl.registerLazySingleton<MatchmakerColleaguesRemoteDataSource>(
    () => MatchmakerColleaguesRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<MatchmakerColleaguesRepository>(
    () => MatchmakerColleaguesRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetColleaguesUseCase(sl()));
  sl.registerLazySingleton(() => GetColleagueConversationsUseCase(sl()));
  sl.registerLazySingleton(() => OpenColleagueChatUseCase(sl()));
  // S2b · colleague-conversations segment — one cubit per mount; the caller
  // passes the current user's id (param1) so self-sent live messages don't
  // bump unread. Reuses the shared realtime port (4c-1).
  sl.registerFactoryParam<MatchmakerColleagueConversationsCubit, String, void>(
    (myUserId, _) => MatchmakerColleagueConversationsCubit(
      getConversations: sl(),
      realtimePort: sl(),
      myUserId: myUserId,
    ),
  );
  // S2b · colleague directory list (paginated roster).
  sl.registerFactory(
    () => MatchmakerColleaguesDirectoryCubit(getColleagues: sl()),
  );
  // S2b · resolves a colleague's conversation before navigating to chat.
  sl.registerFactory(
    () => MatchmakerColleagueOpenChatCubit(openColleagueChat: sl()),
  );

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

  //! ── F5 · Notifications (shared inbox + local unread badge) ───────
  sl.registerLazySingleton<MatchmakerNotificationsRemoteDataSource>(
    () => MatchmakerNotificationsRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<MatchmakerNotificationsRepository>(
    () => MatchmakerNotificationsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => GetNotificationCountUseCase(sl()));
  // One inbox cubit per screen mount.
  sl.registerFactory(
    () => MatchmakerNotificationsCubit(getNotifications: sl()),
  );
  // Shared bell-badge source — SINGLETON so every MatchmakerAppBar + the inbox
  // observe the same unread count. `prefs` resolves the SharedPrefService.
  sl.registerLazySingleton(
    () => MatchmakerNotificationBadgeCubit(getCount: sl(), prefs: sl()),
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

  //! ── S1a · Account (matchmaker/me) ────────────────────────────────
  // Data/domain only here; the MatchmakerAccountCubit (+ its screen wiring)
  // is registered in S1b once the cubit class exists.
  sl.registerLazySingleton<MatchmakerAccountRemoteDataSource>(
    () => MatchmakerAccountRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<MatchmakerAccountRepository>(
    () => MatchmakerAccountRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetMeUseCase(sl()));
  sl.registerLazySingleton(() => UpdateNameUseCase(sl()));
  sl.registerLazySingleton(() => UploadAccountPhotoUseCase(sl()));
  sl.registerLazySingleton(() => DeactivateAccountUseCase(sl()));
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));
  // One cubit per account-screen mount (S1b/S1c).
  sl.registerFactory(
    () => MatchmakerAccountCubit(
      getMe: sl(),
      updateName: sl(),
      uploadPhoto: sl(),
      deactivate: sl(),
      changePassword: sl(),
    ),
  );
}
