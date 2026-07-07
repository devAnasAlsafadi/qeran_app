import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/features/devices/application/device_bootstrap_service.dart';
import 'package:qeran/features/questionnaire/domain/usecases/submit_answers_usecase.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/datasources/change_password_remote_datasource.dart';
import '../data/datasources/profile_image_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/change_password_repository_impl.dart';
import '../data/repositories/profile_image_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/change_password_repository.dart';
import '../domain/repositories/profile_image_repository.dart';
import '../domain/usecases/change_password_usecase.dart';
import '../domain/usecases/login_with_apple_usecase.dart';
import '../domain/usecases/login_with_email_usecase.dart';
import '../domain/usecases/login_with_google_usecase.dart';
import '../domain/usecases/register_user_usecase.dart';
import '../domain/usecases/request_forgot_password_otp_usecase.dart';
import '../domain/usecases/reset_password_usecase.dart';
import '../domain/usecases/send_whatsapp_otp_usecase.dart';
import '../domain/usecases/upload_images_usecase.dart';
import '../domain/usecases/verify_forgot_password_otp_usecase.dart';
import '../domain/usecases/verify_whatsapp_otp_usecase.dart';
import '../presentation/blocs/change_password/change_password_cubit.dart';
import '../presentation/blocs/login/login_bloc.dart';
import '../presentation/blocs/oath/oath_cubit.dart';
import '../presentation/blocs/password_reset/password_reset_bloc.dart';
import '../presentation/blocs/photo_upload/photo_upload_cubit.dart';
import '../presentation/blocs/register/register_bloc.dart';
import '../presentation/blocs/user_session/user_session_cubit.dart';
import '../presentation/blocs/whatsapp/whatsapp_bloc.dart';

Future<void> initAuthDependencies() async {
  //! External — GoogleSignIn v7 uses singleton; initialize it here
  await GoogleSignIn.instance.initialize();
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

  //! DataSources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl(),
      apiConsumer: sl(),
      sharedPref: sl<SharedPrefService>(),
      secureStorage: sl<StorageService>(),
    ),
  );

  sl.registerLazySingleton<ProfileImageRemoteDataSource>(
    () => ProfileImageRemoteDataSourceImpl(
      apiConsumer: sl<ApiConsumer>(),
      secureStorage: sl<StorageService>(),
    ),
  );

  sl.registerLazySingleton<ChangePasswordRemoteDataSource>(
    () => ChangePasswordRemoteDataSourceImpl(apiConsumer: sl<ApiConsumer>()),
  );

  //! Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));

  sl.registerLazySingleton<ProfileImageRepository>(
    () => ProfileImageRepositoryImpl(sl<ProfileImageRemoteDataSource>()),
  );

  sl.registerLazySingleton<ChangePasswordRepository>(
    () => ChangePasswordRepositoryImpl(sl<ChangePasswordRemoteDataSource>()),
  );

  //! UseCases
  sl.registerLazySingleton(() => LoginWithEmailUseCase(sl()));
  sl.registerLazySingleton(() => LoginWithGoogleUseCase(sl()));
  sl.registerLazySingleton(() => LoginWithAppleUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUserUseCase(sl()));
  sl.registerLazySingleton(() => SendWhatsappOtpUseCase(sl()));
  sl.registerLazySingleton(() => VerifyWhatsappOtpUseCase(sl()));
  sl.registerLazySingleton(() => RequestForgotPasswordOtpUseCase(sl()));
  sl.registerLazySingleton(() => VerifyForgotPasswordOtpUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));
  sl.registerLazySingleton(() => UploadImagesUseCase(sl()));

  //! BLoCs / Cubits
  sl.registerFactory(
    () => LoginBloc(
      loginWithEmail: sl(),
      loginWithGoogle: sl(),
      loginWithApple: sl(),
      deviceBootstrap: sl<DeviceBootstrapService>(),
      userSession: sl<UserSessionCubit>(),
    ),
  );

  sl.registerFactory(
    () => RegisterBloc(
      registerUser: sl(),
      userSession: sl<UserSessionCubit>(),
    ),
  );

  sl.registerFactory(
    () => WhatsappBloc(
      sendOtp: sl(),
      verifyOtp: sl(),
      deviceBootstrap: sl<DeviceBootstrapService>(),
      userSession: sl<UserSessionCubit>(),
    ),
  );

  sl.registerFactory(
    () => PasswordResetBloc(
      requestReset: sl(),
      verifyOtp: sl(),
      resetPassword: sl(),
    ),
  );

  sl.registerFactory(
    () => PhotoUploadCubit(
      uploadImages: sl(),
      sharedPrefs: sl<SharedPrefService>(),
    ),
  );

  sl.registerFactory(
    () => OathCubit(
      submitAnswers: sl<SubmitAnswersUseCase>(),
      sharedPrefs: sl<SharedPrefService>(),
      userSession: sl<UserSessionCubit>(),
    ),
  );

  sl.registerFactory(() => ChangePasswordCubit(sl()));
}
