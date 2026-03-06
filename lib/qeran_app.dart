import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'core/constants/app_constants.dart';
import 'core/datasources/secure_storage_service.dart';
import 'core/datasources/shared_pref_service.dart';
import 'core/di/injection_container.dart';
import 'core/routes/app_router.dart';
import 'core/theme/theme.dart';
import 'features/splash/presentation/blocs/splash_cubit.dart';

class QeranApp extends StatelessWidget {
   QeranApp({super.key});

  final AppRouter _appRouter = AppRouter();


  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SplashCubit>(
          create: (context) => sl<SplashCubit>(),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        debugShowCheckedModeBanner: false,
        title: AppConstants.appTitle,
        theme: AppTheme.lightTheme(context.locale),
        darkTheme: AppTheme.darkTheme(context.locale),
        themeMode: ThemeMode.light,
        initialRoute: RouteNames.splashScreen,
        onGenerateRoute: _appRouter.onGenerateRoute,
        builder: (context, child) => ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: [
            const Breakpoint(start: 0, end: 450, name: MOBILE),
            const Breakpoint(start: 451, end: 800, name: TABLET),
            const Breakpoint(start: 801, end: 1920, name: DESKTOP),
            const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
          ],
        ),
      ),
    );
  }
}
