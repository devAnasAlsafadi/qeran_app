import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/app_logger.dart';
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




  await EasyLocalization.ensureInitialized();
  Bloc.observer = SimpleBlocObserver();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale("ar")],
      fallbackLocale: const Locale('en'),
      path: AppAssets.translations,
      startLocale: Locale("ar"),
      child:  QeranApp(),
    ),
  );
}