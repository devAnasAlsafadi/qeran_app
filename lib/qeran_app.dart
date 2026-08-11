import 'dart:async';

import 'package:country_picker/country_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'core/connectivity/connectivity_cubit.dart';
import 'core/constants/app_constants.dart';
import 'core/design_system/theme/qeran_theme.dart';
import 'core/design_system/widgets/qeran_connectivity_banner.dart';
import 'core/di/injection_container.dart';
import 'core/routes/app_router.dart';
import 'core/routes/route_name.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/firebase_initialization_service.dart';
import 'core/services/language_service.dart';
import 'core/utils/app_snackbar.dart';
import 'features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'features/auth/presentation/blocs/user_session/user_session_state.dart';
import 'features/devices/application/device_bootstrap_service.dart';
import 'features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'features/splash/presentation/blocs/splash_cubit.dart';
import 'features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';

class QeranApp extends StatelessWidget {
  const QeranApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Keep the API layer in sync with the active locale.
    // easy_localization triggers a rebuild here every time the locale changes.
    final code = context.locale.languageCode;
    final language = sl<LanguageService>();
    if (language.currentLanguage != code) {
      final switched = language.setLanguage(code);
      unawaited(_notifyLanguageChangedWhenReady(code));
      if (switched) _reloadLocalisedServerState();
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<SplashCubit>(create: (_) => sl<SplashCubit>()),
        BlocProvider<UserSessionCubit>.value(value: sl<UserSessionCubit>()),
        BlocProvider<CurrentSubscriptionCubit>.value(
          value: sl<CurrentSubscriptionCubit>(),
        ),
        BlocProvider<ProfileGateCubit>.value(value: sl<ProfileGateCubit>()),
        BlocProvider<ConnectivityCubit>(
          create: (_) => ConnectivityCubit(service: sl<ConnectivityService>()),
        ),
      ],
      child: MaterialApp(
        navigatorKey: sl<GlobalKey<NavigatorState>>(),
        localizationsDelegates: [
          ...context.localizationDelegates,
          CountryLocalizations.delegate,
        ],
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        debugShowCheckedModeBanner: false,
        title: AppConstants.appTitle,
        theme: QeranTheme.light(context.locale),
        themeMode: ThemeMode.light,
        initialRoute: RouteNames.splashScreen,
        onGenerateRoute: AppRouter().onGenerateRoute,
        builder: (context, child) {
          final responsive = ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: [
              const Breakpoint(start: 0, end: 450, name: MOBILE),
              const Breakpoint(start: 451, end: 800, name: TABLET),
              const Breakpoint(start: 801, end: 1920, name: DESKTOP),
              const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
            ],
          );
          // QER-10: tapping anywhere outside a field closes the keyboard.
          // Done once here, above the Navigator, so it covers every screen in
          // both roles rather than being re-added screen by screen.
          //
          // `translucent` so the tap still reaches whatever is underneath —
          // buttons and list rows keep working, and a child's own tap
          // recogniser wins the arena over this one.
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: AppSnackBarHost(
              child: _ConnectivityBannerHost(child: responsive),
            ),
          );
        },
      ),
    );
  }
}

/// Re-pulls the state that lives ABOVE any screen and carries server-localised
/// text, after the user switches language.
///
/// Screens handle themselves: both shells wrap their tabs in
/// [LocaleRebuildScope], so a switch rebuilds them and their cubits fetch
/// again. These two are app-scoped singletons that no rebuild would touch —
/// the subscription (plan names) and the profile gate (status copy) would go on
/// serving the previous language until something else happened to refresh them.
///
/// Deferred to after the frame: this is reached from `build`, and a cubit
/// emitting mid-build throws.
void _reloadLocalisedServerState() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(sl<CurrentSubscriptionCubit>().refresh(force: true));
    unawaited(sl<ProfileGateCubit>().refresh());
  });
}

Future<void> _notifyLanguageChangedWhenReady(String languageCode) async {
  await sl<FirebaseInitializationService>().ready;
  await sl<DeviceBootstrapService>().onLanguageChanged(languageCode);
}

/// Overlays [QeranConnectivityBanner] above every route. Post-login gate (S9):
/// the banner shows only when the session is authenticated AND offline, so
/// splash and the pre-login auth flow never surface it.
class _ConnectivityBannerHost extends StatelessWidget {
  const _ConnectivityBannerHost({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        PositionedDirectional(
          top: 0,
          start: 0,
          end: 0,
          child: BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
            builder: (context, status) =>
                BlocBuilder<UserSessionCubit, UserSessionState>(
                  builder: (context, session) {
                    final show =
                        status == ConnectivityStatus.offline &&
                        session is UserSessionAuthenticated;
                    return QeranConnectivityBanner(visible: show);
                  },
                ),
          ),
        ),
      ],
    );
  }
}
