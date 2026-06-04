import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/di/injection_container.dart';
import '../data/datasources/questionnaire_remote_datasource.dart';
import '../data/repositories/questionnaire_repository_impl.dart';
import '../domain/repositories/questionnaire_repository.dart';
import '../domain/usecases/fetch_questions_usecase.dart';
import '../domain/usecases/get_edit_form_usecase.dart';
import '../domain/usecases/submit_answers_usecase.dart';
import '../presentation/blocs/profile_edit/profile_edit_cubit.dart';
import '../presentation/blocs/questionnaire_cubit.dart';

void initQuestionnaireDependencies() {
  //! DataSources
  sl.registerLazySingleton<QuestionnaireRemoteDataSource>(
    () => QuestionnaireRemoteDataSourceImpl(apiConsumer: sl()),
  );

  //! Repositories
  sl.registerLazySingleton<QuestionnaireRepository>(
    () => QuestionnaireRepositoryImpl(sl()),
  );

  //! UseCases
  sl.registerLazySingleton(() => FetchQuestionsUseCase(sl()));
  sl.registerLazySingleton(() => GetEditFormUseCase(sl()));
  sl.registerLazySingleton(() => SubmitAnswersUseCase(sl()));

  //! Cubits
  sl.registerFactory(
    () => QuestionnaireCubit(
      fetchQuestions: sl(),
      sharedPrefs: sl<SharedPrefService>(),
    ),
  );
  sl.registerFactory(() => ProfileEditCubit(getEditForm: sl(), submit: sl()));
}
