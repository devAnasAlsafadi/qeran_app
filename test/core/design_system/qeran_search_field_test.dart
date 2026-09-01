import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_search_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The shared search affordance. It is rendered by the filter facet in BOTH
/// apps and by the questionnaire's long option lists, so its contract is
/// pinned here rather than inferred from whichever host happens to use it.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {
        'filters': {'search_hint': 'Search options'},
      };
}

Future<TextEditingController> _pump(
  WidgetTester tester, {
  String? hint,
  ValueChanged<String>? onChanged,
  Locale locale = const Locale('en'),
  ui.TextDirection direction = ui.TextDirection.ltr,
}) async {
  final controller = TextEditingController();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      startLocale: locale,
      // Without this the first pump persists its locale and a later pump in
      // the same test silently reuses it instead of the one asked for.
      saveLocale: false,
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: Scaffold(
            body: Directionality(
              textDirection: direction,
              child: QeranSearchField(
                controller: controller,
                hint: hint,
                onChanged: onChanged ?? (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('carries the magnifier that marks it as a search box', (
    tester,
  ) async {
    await _pump(tester);

    final icon = tester.widget<Icon>(find.byIcon(Icons.search_rounded));
    // Size is pinned because this widget was extracted as a PURE MOVE: the
    // filter facet in both apps renders it, so a changed glyph size here is a
    // silent restyle of discovery and matchmaker explore.
    expect(icon.size, 20);
    expect(icon.color, QeranColors.inkFaint);
  });

  testWidgets('falls back to the shared option-search placeholder', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Search options'), findsOneWidget);
  });

  testWidgets('a caller may override the placeholder', (tester) async {
    await _pump(tester, hint: 'Search countries');

    expect(find.text('Search countries'), findsOneWidget);
    expect(find.text('Search options'), findsNothing);
  });

  testWidgets('reports every keystroke to the host', (tester) async {
    final seen = <String>[];
    await _pump(tester, onChanged: seen.add);

    await tester.enterText(find.byType(TextField), 'jo');

    expect(seen, ['jo']);
  });

  testWidgets('the magnifier mirrors to the other edge under RTL', (
    tester,
  ) async {
    // Passed as `prefix` on purpose: Flutter mirrors `prefixIcon` with the
    // ambient direction, so Arabic gets it on the opposite edge with no manual
    // swap — a hand-placed left/right would double-flip. Asserted by POSITION,
    // so it fails if the mirroring ever stops.
    await _pump(tester);
    final ltrIcon = tester.getCenter(find.byIcon(Icons.search_rounded)).dx;
    final ltrField = tester.getCenter(find.byType(TextField)).dx;
    expect(ltrIcon, lessThan(ltrField));

    await _pump(tester, direction: ui.TextDirection.rtl);
    final rtlIcon = tester.getCenter(find.byIcon(Icons.search_rounded)).dx;
    final rtlField = tester.getCenter(find.byType(TextField)).dx;
    expect(rtlIcon, greaterThan(rtlField));
  });
}
