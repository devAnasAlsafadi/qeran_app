import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/services/notification_service.dart';
import 'package:qeran/core/services/revenuecat_service.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';
import 'package:qeran/features/devices/application/device_bootstrap_service.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'core/di/injection_container.dart' as di;
import 'core/utils/app_assets.dart';
import 'core/utils/app_bloc_observer.dart';
import 'firebase_options.dart';
import 'qeran_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.debug("✅ Firebase Connected Successfully!");
  } catch (e) {
    AppLogger.error("❌ Firebase Connection Failed: $e");
  }

  //  Dependency Injection
  await di.init();

  // Hydrate the user session from storage before runApp so no widget
  // renders against UserSessionInitial.
  await di.sl<UserSessionCubit>().hydrate();

  // Subscription state is hydrated AFTER the user session — the
  // /current endpoint needs the bearer token the session just wrote
  // to secure storage. Fire-and-forget: a slow response must not block
  // launch; widgets render against `CurrentSubscriptionInitial` and
  // observe the transition reactively.
  // Guard: skip the request entirely when there is no authenticated
  // session — avoids a pointless 401 on every cold start for guests.
  if (di.sl<UserSessionCubit>().state is UserSessionAuthenticated) {
    unawaited(di.sl<CurrentSubscriptionCubit>().hydrate());
  }

  // FCM init — wires onTokenRefresh to the device-bootstrap orchestrator.
  // Failures here must not block app launch.
  try {
    await di.sl<NotificationService>().init(
      onTokenRefresh: (token) =>
          di.sl<DeviceBootstrapService>().onTokenRefreshed(token),
    );
  } catch (e) {
    AppLogger.error("NotificationService init failed: $e", tag: 'FCM');
  }

  // RevenueCat (P1) — configure the SDK anonymously, then bind its appUserID
  // to the session. Same non-blocking contract as Firebase/FCM: a payment-SDK
  // failure must never block launch.
  try {
    final rc = di.sl<RevenueCatService>();
    await rc.configure();
    _bindRevenueCatToSession(di.sl<UserSessionCubit>(), rc);
  } catch (e) {
    AppLogger.error("RevenueCat init failed: $e", tag: 'RC');
  }

  await EasyLocalization.ensureInitialized();
  // Load intl date symbols for all locales so locale-aware DateFormat
  // (e.g. the matchmaker dashboard greeting) works in Arabic + English.
  await initializeDateFormatting();
  Bloc.observer = SimpleBlocObserver();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      // Arabic-first audience: when no saved locale exists yet (fresh
      // install) start in Arabic. easy_localization's default
      // `saveLocale: true` still applies, so a user who later picks
      // English via the language switcher keeps that choice across
      // launches.
      startLocale: const Locale('ar'),
      fallbackLocale: const Locale('ar'),
      path: AppAssets.translations,
      child: QeranApp(),
    ),
  );
}

/// Keeps RevenueCat's `appUserID` in sync with the backend session, without
/// giving [UserSessionCubit] a payment dependency (the coupling lives here,
/// mirroring how FCM is wired in `main`). Identifies an already-authenticated
/// session immediately, then follows future sign-in / sign-out transitions.
void _bindRevenueCatToSession(UserSessionCubit session, RevenueCatService rc) {
  final current = session.state;
  if (current is UserSessionAuthenticated && current.user.id.isNotEmpty) {
    unawaited(rc.logIn(current.user.id));
  }
  session.stream.listen((state) {
    if (state is UserSessionAuthenticated && state.user.id.isNotEmpty) {
      unawaited(rc.logIn(state.user.id));
    } else if (state is UserSessionUnauthenticated) {
      unawaited(rc.logOut());
    }
  });
}
