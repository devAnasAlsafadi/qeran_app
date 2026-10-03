import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The shipped translation files, read from disk. Synchronous on purpose:
/// an awaited read does not complete inside `pumpAndSettle`.
class _DiskLoader extends AssetLoader {
  const _DiskLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final file = File('assets/translations/${locale.languageCode}.json');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }
}

/// Call from `setUpAll` before [pumpShippedStrings].
Future<void> initShippedStrings() async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
}

/// Pumps [child] in [locale] with the shipped strings, configured as
/// `main.dart` configures them (Arabic fallback, plural rules on), and
/// returns a context inside.
Future<BuildContext> pumpShippedStrings(
  WidgetTester tester,
  Locale locale, {
  Widget child = const SizedBox(),
}) async {
  late BuildContext inside;
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      startLocale: locale,
      fallbackLocale: const Locale('ar'),
      ignorePluralRules: false,
      saveLocale: false,
      path: 'assets/translations',
      assetLoader: const _DiskLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: Builder(
            builder: (c) {
              inside = c;
              return Scaffold(body: child);
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return inside;
}
