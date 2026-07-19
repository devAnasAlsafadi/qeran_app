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
import '../../features/legal/di/legal_injection.dart';
import '../../features/likes/di/likes_injection.dart';
import '../../features/matchmaker/di/matchmaker_injection.dart';
import '../../features/notifications/di/notifications_injection.dart';
import '../../features/profile/di/profile_injection.dart';
import '../../features/questionnaire/di/questionnaire_injection.dart';
import '../../features/block/di/block_injection.dart';
import '../../features/report/di/report_injection.dart';
import '../../features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../../features/splash/presentation/blocs/splash_cubit.dart';
import '../../features/subscriptions/di/subscriptions_injection.dart';
import '../../features/support/di/support_injection.dart';
import '../api/api_consumer.dart';
import '../api/http_consumer.dart';
import '../services/connectivity_service.dart';
import '../services/connectivity_service_impl.dart';
import '../datasources/shared_pref_service.dart';
import '../datasources/secure_storage_service.dart';
import '../services/device_info_service.dart';
import '../services/language_service.dart';
import '../services/notification_service.dart';
import '../services/revenuecat_service.dart';
import '../services/storage_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Language
  sl.registerSingleton<LanguageService>(LanguageService());

  //! App-wide navigator key — attached to MaterialApp.navigatorKey and
  //  used by infrastructure that needs a navigator without a build
  //  context (e.g. showing a dialog without the screen having to
  //  bind/unbind a static reference).
  sl.registerSingleton<GlobalKey<NavigatorState>>(
    GlobalKey<NavigatorState>(debugLabel: 'rootNavigator'),
  );

  //! External
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPrefs);
  // Pin explicit Android ciphers so the cipher is deterministic across
  // launches — the v10 default's auto-detected "algorithm change" was
  // wiping the JWT every cold start (RSA→AES_GCM migration → "Migrated 0
  // items" → token gone → 401 → splash bounced to onboarding). resetOnError
  // stays true so the one legacy undecryptable entry is cleared cleanly
  // (without throwing) on the first launch after the fix; a single re-login
  // then persists across all subsequent restarts. iOS uses the Keychain and
  // is unaffected.
  sl.registerLazySingleton(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(
        resetOnError: true,
        keyCipherAlgorithm:
            KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      ),
    ),
  );
  sl.registerLazySingleton(() => http.Client());

  //! Storage
  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(sl()),
  );
  sl.registerLazySingleton<SharedPrefService>(() => SharedPrefService(sl()));
  sl.registerLazySingleton<StorageService>(() => sl<SecureStorageService>());

  //! Network
  // Connectivity signal — registered before ApiConsumer, which will consume it
  // for the offline pre-flight in a later sub-step.
  sl.registerLazySingleton<ConnectivityService>(
    () => ConnectivityServiceImpl(),
  );
  sl.registerLazySingleton<ApiConsumer>(
    () => HttpConsumer(
      client: sl(),
      storage: sl(),
      languageService: sl(),
      connectivity: sl(),
    ),
  );

  //! Devices / FCM infrastructure
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<DeviceInfoService>(() => DeviceInfoService());

  //! Payments — RevenueCat (P1: init + identity only). Configured from
  //  main(); identity bound to UserSessionCubit. The custom-checkout +
  //  client-discount layer was retired ahead of the IAP rebuild (P1b);
  //  purchasing will route through RevenueCat.
  sl.registerLazySingleton<RevenueCatService>(() => RevenueCatService());

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

  //! Features - Notifications (user-app shared inbox)
  initNotificationsDependencies();

  //! Features - Legal (privacy-policy + terms-and-conditions)
  initLegalDependencies();

  //! Features - Support (Help & Support — categories + ticket submission)
  initSupportDependencies();

  //! Features — Report + Block (UGC safety)
  initReportDependencies();
  initBlockDependencies();

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
