import 'package:qeran/core/di/injection_container.dart';

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

/// Her compatibility cases and their notes.
/// Called by [initMatchmakerDependencies].
void initMatchmakerCasesDependencies() {
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
}
