import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_empty_view.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A filtered deck that comes back empty is a DEAD END without these actions:
/// the filter button lives on the card photo, and there is no card. The only
/// way out was force-quitting the app.
///
/// The unfiltered empty state must NOT grow the same buttons — there is no
/// filter to edit, and offering one would be a lie about why the deck is empty.

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

Future<void> _pump(
  WidgetTester tester, {
  required bool hasFilters,
  VoidCallback? onEdit,
  VoidCallback? onClear,
  bool withHandlers = true,
  bool canReplay = false,
  VoidCallback? onReplay,
}) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar')],
      startLocale: const Locale('ar'),
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: Scaffold(
            body: DiscoveryEmptyView(
              hasFilters: hasFilters,
              onEditFilters: withHandlers ? (onEdit ?? () {}) : null,
              onClearFilters: withHandlers ? (onClear ?? () {}) : null,
              canReplay: canReplay,
              onReplay: onReplay,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('no filters — no actions, and the copy says nobody is left', (
    tester,
  ) async {
    await _pump(tester, hasFilters: false);

    expect(find.byType(QeranButton), findsNothing);
    expect(find.text(LocaleKeys.discovery_empty_title), findsOneWidget);
  });

  testWidgets('filtered — offers a way back to the filter sheet', (
    tester,
  ) async {
    await _pump(tester, hasFilters: true);

    // Different copy: "nobody matched YOUR FILTER", not "nobody exists".
    expect(
      find.text(LocaleKeys.discovery_empty_filtered_title),
      findsOneWidget,
    );
    expect(find.byType(QeranButton), findsNWidgets(2));
  });

  testWidgets('exhausted local deck offers replay and invokes it', (
    tester,
  ) async {
    var replays = 0;
    await _pump(
      tester,
      hasFilters: false,
      canReplay: true,
      onReplay: () => replays++,
    );

    expect(find.text(LocaleKeys.discovery_empty_replay), findsOneWidget);
    await tester.tap(find.text(LocaleKeys.discovery_empty_replay));
    expect(replays, 1);
  });

  testWidgets('editing reopens the sheet', (tester) async {
    var edits = 0;
    await _pump(tester, hasFilters: true, onEdit: () => edits++);

    await tester.tap(find.text(LocaleKeys.discovery_empty_edit_filters));
    await tester.pumpAndSettle();

    expect(edits, 1);
  });

  testWidgets('clearing drops the filters', (tester) async {
    var clears = 0;
    await _pump(tester, hasFilters: true, onClear: () => clears++);

    await tester.tap(find.text(LocaleKeys.discovery_empty_clear_filters));
    await tester.pumpAndSettle();

    expect(clears, 1);
  });

  testWidgets('no actions without handlers, even when filtered', (
    tester,
  ) async {
    // Belt and braces: a caller that cannot service the buttons must not be
    // able to render dead ones.
    await _pump(tester, hasFilters: true, withHandlers: false);

    expect(find.byType(QeranButton), findsNothing);
  });
}
