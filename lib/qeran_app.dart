import 'package:country_picker/country_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart';
import 'core/routes/app_router.dart';
import 'core/routes/route_name.dart';
import 'core/theme/theme.dart';
import 'features/splash/presentation/blocs/splash_cubit.dart';

class QeranApp extends StatelessWidget {
  const QeranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SplashCubit>(create: (_) => sl<SplashCubit>()),
      ],
      child: MaterialApp(
        localizationsDelegates: [
          ...context.localizationDelegates,
          CountryLocalizations.delegate,
        ],
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        debugShowCheckedModeBanner: false,
        title: AppConstants.appTitle,
        theme: AppTheme.lightTheme(context.locale),
        darkTheme: AppTheme.darkTheme(context.locale),
        themeMode: ThemeMode.light,
        initialRoute: RouteNames.splashScreen,
        onGenerateRoute: AppRouter().onGenerateRoute,
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
