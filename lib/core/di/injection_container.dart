import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/di/auth_injection.dart';
import '../../features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import '../../features/chat/di/chat_injection.dart';
import '../../features/devices/di/devices_injection.dart';
import '../../features/discovery/di/discovery_injection.dart';
import '../../features/likes/di/likes_injection.dart';
import '../../features/matchmaker/di/matchmaker_injection.dart';
import '../../features/profile/di/profile_injection.dart';
import '../../features/questionnaire/di/questionnaire_injection.dart';
import '../../features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../../features/splash/presentation/blocs/splash_cubit.dart';
import '../../features/subscriptions/di/subscriptions_injection.dart';
import '../api/api_consumer.dart';
import '../api/http_consumer.dart';
import '../datasources/shared_pref_service.dart';
import '../datasources/secure_storage_service.dart';
import '../services/device_info_service.dart';
import '../services/language_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Language
  sl.registerSingleton<LanguageService>(LanguageService());

  //! App-wide navigator key — attached to MaterialApp.navigatorKey and
  //  used by infrastructure that needs a navigator without a build
  //  context (e.g. the dev-only FakePaymentGateway to show a dialog
  //  without the screen having to bind/unbind a static reference).
  sl.registerSingleton<GlobalKey<NavigatorState>>(
    GlobalKey<NavigatorState>(debugLabel: 'rootNavigator'),
  );

  //! External
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPrefs);
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => http.Client());

  //! Storage
  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(sl()),
  );
  sl.registerLazySingleton<SharedPrefService>(() => SharedPrefService(sl()));
  sl.registerLazySingleton<StorageService>(() => sl<SecureStorageService>());

  //! Network
  sl.registerLazySingleton<ApiConsumer>(
    () => HttpConsumer(
      client: sl(),
      storage: sl(),
      languageService: sl(),
    ),
  );

  //! Devices / FCM infrastructure
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<DeviceInfoService>(() => DeviceInfoService());

  //! Features - Auth
  await initAuthDependencies();

  //! User Session — app-scoped Cubit.
  //
  // Deviates from §2 of CLAUDE.md ("registerFactory for Cubits"): this
  // cubit holds app-lifetime state and is provided once at the root via
  // BlocProvider.value. A factory would either yield a new instance per
  // `sl()` call (breaking state continuity) or require manual instance
  // reuse plumbing. Lazy singleton is the correct fit here.
  sl.registerLazySingleton<UserSessionCubit>(
    () => UserSessionCubit(
      secureStorage: sl<StorageService>(),
      sharedPrefs: sl<SharedPrefService>(),
    ),
  );

  //! Features - Devices
  initDevicesDependencies();

  //! Features - Questionnaire
  initQuestionnaireDependencies();

  //! Features - Discovery
  initDiscoveryDependencies();

  //! Features - Subscriptions
  initSubscriptionDependencies();

  //! Features - Likes / Interests
  initLikesDependencies();

  //! Features - Chat (User ↔ Matchmaker)
  initChatDependencies();

  //! Features - Profile (shared reusable surface)
  initProfileDependencies();

  //! Features - Matchmaker (role=Moderator) — foundation only.
  // Currently a no-op; each subsequent milestone fills it.
  await initMatchmakerDependencies();

  //! Features - Onboarding
  sl.registerFactory(
    () => OnboardingCubit(sharedPref: sl<SharedPrefService>()),
  );

  //! Features - Splash
  sl.registerFactory(
    () => SplashCubit(
      secureStorage: sl<SecureStorageService>(),
      sharedPrefs: sl<SharedPrefService>(),
    ),
  );
}
