import 'package:qeran/core/di/injection_container.dart';

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

/// Her Users tab: the lists, a user's profile, its actions, answers and notes.
/// Called by [initMatchmakerDependencies].
void initMatchmakerUsersDependencies() {
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
}
