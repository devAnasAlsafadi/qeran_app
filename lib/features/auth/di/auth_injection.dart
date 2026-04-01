import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/services/storage_service.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/datasources/profile_image_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/profile_image_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/profile_image_repository.dart';
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
import '../presentation/blocs/login/login_bloc.dart';
import '../presentation/blocs/password_reset/password_reset_bloc.dart';
import '../presentation/blocs/photo_upload/photo_upload_cubit.dart';
import '../presentation/blocs/register/register_bloc.dart';
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
      httpClient: sl<http.Client>(),
      secureStorage: sl<StorageService>(),
    ),
  );

  //! Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<ProfileImageRepository>(
    () => ProfileImageRepositoryImpl(sl<ProfileImageRemoteDataSource>()),
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
  sl.registerLazySingleton(() => UploadImagesUseCase(sl()));

  //! BLoCs / Cubits
  sl.registerFactory(
    () => LoginBloc(
      loginWithEmail: sl(),
      loginWithGoogle: sl(),
      loginWithApple: sl(),
    ),
  );

  sl.registerFactory(() => RegisterBloc(registerUser: sl()));

  sl.registerFactory(
    () => WhatsappBloc(sendOtp: sl(), verifyOtp: sl()),
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
      uploadImagesUseCase: sl(),
      sharedPrefService: sl<SharedPrefService>(),
    ),
  );
}
