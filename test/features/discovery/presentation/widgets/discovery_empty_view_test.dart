import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_empty_view.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The terminal deck state has two INDEPENDENT causes — the server saying a
/// query matched nobody, and the user having swiped through everything — and
/// each carries a different remedy. These pin that all four combinations render
/// their own copy, that no branch paints a button it cannot service, and that a
/// filtered dead end always keeps a way back to the filter sheet.
///
/// The stub loader resolves nothing, so translation returns the key itself and
/// the assertions read as key identity rather than as copy.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

Future<void> _pump(
  WidgetTester tester, {
  bool seenEveryone = false,
  bool filtersMatchedNobody = false,
  VoidCallback? onRefresh,
  VoidCallback? onEditFilters,
  VoidCallback? onStartOver,
  bool startingOver = false,
  bool withHandlers = true,
  // A button in its loading state runs a never-ending spinner, so settling
  // would spin until the timeout. That case pumps a single frame instead.
  bool settle = true,
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
              seenEveryone: seenEveryone,
              filtersMatchedNobody: filtersMatchedNobody,
              onRefresh: withHandlers ? (onRefresh ?? () {}) : null,
              onEditFilters: withHandlers ? (onEditFilters ?? () {}) : null,
              onStartOver: onStartOver,
              startingOver: startingOver,
            ),
          ),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Matched on the widget's own `label` rather than on rendered text: a button
/// in its loading state swaps the label out for a spinner, and finding by text
/// would fail on exactly the case worth asserting.
QeranButton _buttonWith(WidgetTester tester, String labelKey) => tester
    .widgetList<QeranButton>(find.byType(QeranButton))
    .firstWhere((b) => b.label == labelKey);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('branch (a) — seen everyone, no filter problem', () {
    testWidgets('shows the completion copy and a single refresh action', (
      tester,
    ) async {
      await _pump(tester, seenEveryone: true);

      expect(
        find.text(LocaleKeys.discovery_empty_seen_all_title),
        findsOneWidget,
      );
      expect(
        find.text(LocaleKeys.discovery_empty_seen_all_message),
        findsOneWidget,
      );
      expect(find.byType(QeranButton), findsOneWidget);
      expect(
        find.text(LocaleKeys.discovery_empty_seen_all_cta_refresh),
        findsOneWidget,
      );
    });

    testWidgets('refreshing invokes the handler', (tester) async {
      var refreshes = 0;
      await _pump(tester, seenEveryone: true, onRefresh: () => refreshes++);

      await tester.tap(
        find.text(LocaleKeys.discovery_empty_seen_all_cta_refresh),
      );
      await tester.pumpAndSettle();

      expect(refreshes, 1);
    });
  });

  group('branch (b) — the filter matched nobody', () {
    testWidgets('keeps the existing filtered copy and offers the sheet', (
      tester,
    ) async {
      await _pump(tester, filtersMatchedNobody: true);

      expect(
        find.text(LocaleKeys.discovery_empty_filtered_title),
        findsOneWidget,
      );
      expect(
        find.text(LocaleKeys.discovery_empty_filtered_subtitle),
        findsOneWidget,
      );
      expect(find.byType(QeranButton), findsOneWidget);
      expect(find.text(LocaleKeys.discovery_empty_edit_filters), findsOneWidget);
    });

    testWidgets('editing reopens the sheet', (tester) async {
      var edits = 0;
      await _pump(
        tester,
        filtersMatchedNobody: true,
        onEditFilters: () => edits++,
      );

      await tester.tap(find.text(LocaleKeys.discovery_empty_edit_filters));
      await tester.pumpAndSettle();

      expect(edits, 1);
    });
  });

  group('branch (c) — both at once', () {
    testWidgets('leads with the filter headline but merges both concerns', (
      tester,
    ) async {
      await _pump(tester, seenEveryone: true, filtersMatchedNobody: true);

      expect(
        find.text(LocaleKeys.discovery_empty_filtered_title),
        findsOneWidget,
      );
      expect(
        find.text(LocaleKeys.discovery_empty_filtered_seen_all_message),
        findsOneWidget,
      );
      // NOT the single-cause message — that would drop half the explanation.
      expect(
        find.text(LocaleKeys.discovery_empty_filtered_subtitle),
        findsNothing,
      );
    });

    testWidgets('offers both remedies, start-over primary and filters ghost', (
      tester,
    ) async {
      await _pump(
        tester,
        seenEveryone: true,
        filtersMatchedNobody: true,
        onStartOver: () {},
      );

      expect(find.byType(QeranButton), findsNWidgets(2));
      expect(
        _buttonWith(tester, LocaleKeys.discovery_empty_start_over).variant,
        QeranButtonVariant.primaryGold,
      );
      expect(
        _buttonWith(tester, LocaleKeys.discovery_empty_edit_filters).variant,
        QeranButtonVariant.ghost,
      );
    });

    testWidgets('start over invokes its handler', (tester) async {
      var resets = 0;
      await _pump(
        tester,
        seenEveryone: true,
        filtersMatchedNobody: true,
        onStartOver: () => resets++,
      );

      await tester.tap(find.text(LocaleKeys.discovery_empty_start_over));
      await tester.pumpAndSettle();

      expect(resets, 1);
    });

    // The deliberate exception to the no-dead-buttons rule, and the reason it
    // is safe: a caller that cannot service the reset gets the action painted
    // disabled by QeranButton rather than one that fails on tap.
    testWidgets('start over renders disabled when it has no handler', (
      tester,
    ) async {
      await _pump(tester, seenEveryone: true, filtersMatchedNobody: true);

      expect(find.text(LocaleKeys.discovery_empty_start_over), findsOneWidget);
      expect(
        _buttonWith(tester, LocaleKeys.discovery_empty_start_over).onPressed,
        isNull,
      );
    });

    testWidgets('start over takes the loading treatment while in flight', (
      tester,
    ) async {
      await _pump(
        tester,
        seenEveryone: true,
        filtersMatchedNobody: true,
        onStartOver: () {},
        startingOver: true,
        settle: false,
      );

      expect(
        _buttonWith(tester, LocaleKeys.discovery_empty_start_over).loading,
        isTrue,
      );
    });
  });

  group('branch (d) — nothing known', () {
    testWidgets('falls back to the generic copy with no actions', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text(LocaleKeys.discovery_empty_title), findsOneWidget);
      expect(find.text(LocaleKeys.discovery_empty_subtitle), findsOneWidget);
      expect(find.byType(QeranButton), findsNothing);
    });
  });

  group('no branch paints a button it cannot service', () {
    testWidgets('seen-everyone without a refresh handler', (tester) async {
      await _pump(tester, seenEveryone: true, withHandlers: false);

      expect(find.byType(QeranButton), findsNothing);
    });

    testWidgets('filtered without an edit handler', (tester) async {
      await _pump(tester, filtersMatchedNobody: true, withHandlers: false);

      expect(find.byType(QeranButton), findsNothing);
    });
  });
}
