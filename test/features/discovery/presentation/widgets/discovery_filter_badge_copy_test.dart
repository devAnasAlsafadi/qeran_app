import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_title_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The translation files the app ships, read straight from disk: the asset
/// bundle's own loading never finishes under the test clock.
class _ShippedLoader extends AssetLoader {
  const _ShippedLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
          as Map<String, dynamic>;
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  // The shipped Arabic, not a stub: «عدد» is what lets a count of 1 read
  // naturally, so the wording itself is guarded.
  testWidgets('in Arabic, the filter pill counts with «عدد»', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ar')],
        path: 'assets/translations',
        assetLoader: const _ShippedLoader(),
        child: Builder(
          builder: (ctx) => MaterialApp(
            locale: ctx.locale,
            supportedLocales: ctx.supportedLocales,
            localizationsDelegates: ctx.localizationDelegates,
            home: Scaffold(
              body: DiscoveryTitleRow(
                onPhoto: false,
                activeFilterCount: 1,
                onEditFilters: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('تعديل الفلترة، عدد الفلاتر المفعّلة: 1'),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
