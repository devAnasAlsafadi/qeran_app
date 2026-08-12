import 'package:qeran/core/di/injection_container.dart';

import '../../auth/presentation/blocs/user_session/user_session_cubit.dart';
import '../../devices/application/device_bootstrap_service.dart';
import '../data/datasources/profile_remote_datasource.dart';
import '../data/repositories/profile_repository_impl.dart';
import '../domain/repositories/profile_repository.dart';
import '../domain/usecases/delete_account_usecase.dart';
import '../domain/usecases/add_profile_images_usecase.dart';
import '../domain/usecases/delete_profile_image_usecase.dart';
import '../domain/usecases/get_basic_user_usecase.dart';
import '../domain/usecases/get_my_profile_usecase.dart';
import '../domain/usecases/get_profile_images_usecase.dart';
import '../domain/usecases/get_profile_by_id_usecase.dart';
import '../domain/usecases/set_main_profile_image_usecase.dart';
import '../presentation/blocs/delete_account/delete_account_cubit.dart';
import '../presentation/blocs/my_profile/my_profile_cubit.dart';
import '../presentation/blocs/profile_gate/profile_gate_cubit.dart';
import '../presentation/blocs/profile_photos/profile_photos_cubit.dart';
import '../presentation/blocs/profile_reaction/profile_reaction_cubit.dart';
import '../presentation/blocs/profile_details/profile_details_cubit.dart';
import '../../subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import '../presentation/blocs/share_with_matchmaker/share_with_matchmaker_cubit.dart';

void initProfileDependencies() {
  //! DataSource
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(apiConsumer: sl()),
  );

  //! Repository
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl()),
  );

  //! UseCases
  sl.registerLazySingleton(() => GetMyProfileUseCase(sl()));
  sl.registerLazySingleton(() => GetProfileImagesUseCase(sl()));
  sl.registerLazySingleton(() => AddProfileImagesUseCase(sl()));
  sl.registerLazySingleton(() => DeleteProfileImageUseCase(sl()));
  sl.registerLazySingleton(() => SetMainProfileImageUseCase(sl()));
  // App-scoped approval gate (app-lifetime state → lazy singleton, not a
  // factory; provided at the app root, loaded when the user shell mounts).
  sl.registerLazySingleton(() => ProfileGateCubit(getMyProfile: sl()));
  sl.registerLazySingleton(() => GetProfileByIdUseCase(sl()));
  sl.registerLazySingleton(() => GetBasicUserUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAccountUseCase(sl()));

  //! Cubits (screen-scoped per CLAUDE.md §2)
  sl.registerFactory(() => ProfileDetailsCubit(getProfileById: sl()));
  sl.registerFactory(
    () => ProfileReactionCubit(
      likeProfile: sl(),
      passProfile: sl(),
      profileGate: sl<ProfileGateCubit>(),
      onLikeSuccess: sl<CurrentSubscriptionCubit>().onActionConsumedCounter,
    ),
  );
  sl.registerFactory(() => MyProfileCubit(getMyProfile: sl()));
  sl.registerFactory(
    () => ProfilePhotosCubit(
      getImages: sl(),
      addImages: sl(),
      deleteImage: sl(),
      setMain: sl(),
    ),
  );
  sl.registerFactory(
    () => DeleteAccountCubit(
      deleteAccount: sl(),
      deviceBootstrap: sl<DeviceBootstrapService>(),
      session: sl<UserSessionCubit>(),
    ),
  );
  // ShareWithMatchmakerCubit reads `GetMyMatchmakerUseCase` and
  // `ShareProfileUseCase` from the chat feature's DI module — both
  // are already registered as lazy singletons there.
  sl.registerFactory(
    () => ShareWithMatchmakerCubit(getMyMatchmaker: sl(), shareProfile: sl()),
  );
}
