import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_filter_searchable_facet.dart';
import 'package:qeran/core/design_system/widgets/qeran_selectable_option.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Run 10 (Anas): an opened country list in a long filter sheet stays open,
/// with its search, when scrolled out of view and back. Sheets build their
/// facets lazily, so without a keep-alive it came back closed and cleared. A
/// closed list is let go as before.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {
        'filters': {'search_hint': 'Search', 'search_empty': 'None'},
      };
}

final _options = [
  for (var i = 0; i < 30; i++)
    QeranSelectableOption(value: 'v$i', display: 'Country $i'),
];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  late ScrollController scroll;
  late ValueNotifier<int> reset;

  Future<void> pump(WidgetTester tester) async {
    scroll = ScrollController();
    reset = ValueNotifier(0);
    addTearDown(scroll.dispose);
    addTearDown(reset.dispose);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/translations',
        assetLoader: const _StubAssetLoader(),
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: Scaffold(
              body: ValueListenableBuilder<int>(
                valueListenable: reset,
                builder: (_, version, _) => ListView(
                  controller: scroll,
                  children: [
                    QeranFilterSearchableFacet(
                      label: 'Nationality',
                      options: _options,
                      isSelected: (_) => false,
                      onTap: (_) {},
                      resetVersion: version,
                    ),
                    const SizedBox(height: 5000),
                    const Text('end'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> awayAndBack(WidgetTester tester) async {
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
  }

  Finder facetState() =>
      find.byType(QeranFilterSearchableFacet, skipOffstage: false);

  Future<void> openAndSearch(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Country 2');
    await tester.pumpAndSettle();
    // The keyboard closed, as it does once she scrolls on: a focused field
    // keeps its item alive on its own, which would hide what this tests.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  testWidgets('open, scrolled away and back: still open, search kept', (
    tester,
  ) async {
    await pump(tester);
    await openAndSearch(tester);

    await awayAndBack(tester);

    expect(find.byType(TextField), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Country 2',
    );
  });

  testWidgets('open and far away: still built', (tester) async {
    await pump(tester);
    await openAndSearch(tester);

    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();

    expect(facetState(), findsOneWidget);
  });

  testWidgets('closed and far away: let go', (tester) async {
    await pump(tester);

    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();

    expect(facetState(), findsNothing);
  });

  testWidgets('opened, closed again, then far away: let go', (tester) async {
    await pump(tester);
    await openAndSearch(tester);
    await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
    await tester.pumpAndSettle();

    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();

    expect(facetState(), findsNothing);
  });

  testWidgets('closed by a clear-all, then far away: let go', (tester) async {
    await pump(tester);
    await openAndSearch(tester);
    reset.value++;
    await tester.pumpAndSettle();

    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();

    expect(facetState(), findsNothing);
  });
}
