import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/services/notification_service.dart';
import 'package:qeran/core/services/revenuecat_service.dart';
import 'package:qeran/core/services/firebase_initialization_service.dart';
import 'package:qeran/core/services/google_sign_in_service.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';
import 'package:qeran/features/devices/application/device_bootstrap_service.dart';
import 'core/di/injection_container.dart' as di;
import 'core/utils/app_assets.dart';
import 'core/utils/app_bloc_observer.dart';
import 'qeran_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep only root-widget prerequisites on the cold-start path. These jobs are
  // independent, so running them together avoids serial startup latency.
  await Future.wait<void>([di.init(), EasyLocalization.ensureInitialized()]);

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
      child: const QeranApp(),
    ),
  );

  // These SDKs are not needed to paint the first Flutter frame. Starting them
  // after it keeps launch responsive without removing any functionality.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializeDeferredServices());
  });
}

Future<void> _initializeDeferredServices() async {
  final session = di.sl<UserSessionCubit>();
  final firebase = di.sl<FirebaseInitializationService>();
  final firebaseReady = firebase.initialize();
  unawaited(_initializeRevenueCat(session));
  unawaited(_initializeGoogleSignIn());
  unawaited(_initializeSupportedDateFormatting());
  await firebaseReady;
  await _initializeNotifications();
  unawaited(di.sl<DeviceBootstrapService>().bootstrap());
}

Future<void> _initializeNotifications() async {
  try {
    await di.sl<NotificationService>().init(
      onTokenRefresh: (token) =>
          di.sl<DeviceBootstrapService>().onTokenRefreshed(token),
    );
  } catch (e) {
    AppLogger.error("NotificationService init failed: $e", tag: 'FCM');
  }
}

Future<void> _initializeRevenueCat(UserSessionCubit session) async {
  try {
    final rc = di.sl<RevenueCatService>();
    await rc.configure();
    _bindRevenueCatToSession(session, rc);
  } catch (e) {
    AppLogger.error("RevenueCat init failed: $e", tag: 'RC');
  }
}

Future<void> _initializeGoogleSignIn() async {
  try {
    await di.sl<GoogleSignInService>().initialize();
  } catch (e) {
    AppLogger.error("Google Sign-In init failed: $e", tag: 'AUTH');
  }
}

Future<void> _initializeSupportedDateFormatting() async {
  try {
    await Future.wait<void>([
      initializeDateFormatting('ar'),
      initializeDateFormatting('en'),
    ]);
  } catch (e) {
    AppLogger.error("Date formatting init failed: $e", tag: 'INTL');
  }
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
