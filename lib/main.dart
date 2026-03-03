import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/constants/app_constants.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'core/di/injection_container.dart' as di;
import 'core/utils/app_assets.dart';
import 'core/utils/app_bloc_observer.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase Connected Successfully!");
  } catch (e) {
    print("❌ Firebase Connection Failed: $e");
  }
  await di.init();

  await EasyLocalization.ensureInitialized();

  Bloc.observer = SimpleBlocObserver();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale("ar")],
      fallbackLocale: const Locale('en'),
      // startLocale: Locale('ar'),
      path: AppAssets.translations,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      debugShowCheckedModeBanner: false,
      title: AppConstants.appTitle,

      builder: (context, child) => ResponsiveBreakpoints(
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
        child: child!,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Qeran App Infrastructure Ready!'),
        ),
      ),
    );
  }
}
