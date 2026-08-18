import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_filter_searchable_facet.dart';
import 'package:qeran/core/design_system/widgets/qeran_selectable_option.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The facet is now a design-system widget shared by BOTH apps, so these tests
/// cover the user app's discovery sheet and the matchmaker's explore sheet at
/// once. It takes [QeranSelectableOption] rather than a feature entity —
/// nothing in `lib/core` may import `lib/features`.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {
        'filters': {
          'search_hint': 'Search options',
          'search_empty': 'No matching options',
        },
      };
}

List<QeranSelectableOption> _options(int count) =>
    List<QeranSelectableOption>.generate(
      count,
      (i) => QeranSelectableOption(value: 'value-$i', display: 'Option $i'),
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  /// Hosts the facet under a live locale with a mutable selection set, so a
  /// test can drive `resetVersion` the way a "clear all" does.
  Future<
    ({
      void Function(void Function()) rebuild,
      Set<String> selected,
      void Function() bumpReset,
    })
  >
  pumpFacet(
    WidgetTester tester, {
    int optionCount = 12,
    Set<String> initiallySelected = const {},
    bool allowsMultiple = false,
  }) async {
    final selected = <String>{...initiallySelected};
    final options = _options(optionCount);
    var resetVersion = 0;
    late StateSetter rebuild;

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
              body: StatefulBuilder(
                builder: (context, setState) {
                  rebuild = setState;
                  return QeranFilterSearchableFacet(
                    label: 'Nationality',
                    options: options,
                    isSelected: selected.contains,
                    onTap: selected.add,
                    allowsMultiple: allowsMultiple,
                    resetVersion: resetVersion,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return (
      rebuild: rebuild,
      selected: selected,
      bumpReset: () => rebuild(() => resetVersion++),
    );
  }

  Future<void> expand(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();
  }

  /// Scoped to the checklist. A bare `find.text` would also match the search
  /// field's own contents and the collapsed trigger's selection summary — both
  /// legitimately render the same string.
  Finder row(String label) => find.descendant(
    of: find.byType(ListView),
    matching: find.text(label),
  );

  /// Indicators live in the checklist; the trigger's chevron and the search
  /// field's magnifier are icons too, so scope the same way `row` does.
  Finder indicator(IconData icon) => find.descendant(
    of: find.byType(ListView),
    matching: find.byIcon(icon),
  );

  Color? indicatorColor(WidgetTester tester, IconData icon) =>
      tester.widget<Icon>(indicator(icon).first).color;

  testWidgets('starts collapsed, showing the label as placeholder', (
    tester,
  ) async {
    await pumpFacet(tester);

    expect(find.byIcon(Icons.search_rounded), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
  });

  testWidgets('expanding puts the cursor straight in the search box', (
    tester,
  ) async {
    await pumpFacet(tester);
    await expand(tester);

    // The only reason to open a long list is to narrow it, so the field must
    // be focused without a second tap. Deferred a frame in the widget, which
    // is why this asserts after pumpAndSettle.
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode?.hasFocus, isTrue);
  });

  testWidgets('typing narrows the list; a miss shows the empty message', (
    tester,
  ) async {
    await pumpFacet(tester);
    await expand(tester);

    await tester.enterText(find.byType(TextField), 'Option 1');
    await tester.pumpAndSettle();
    // A `contains` match, so "Option 1" also keeps "Option 10" and "Option 11"
    // — but "Option 0" is gone.
    expect(row('Option 0'), findsNothing);
    expect(row('Option 1'), findsOneWidget);
    expect(row('Option 10'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No matching options'), findsOneWidget);
  });

  testWidgets('a selected option stays visible under a non-matching query', (
    tester,
  ) async {
    await pumpFacet(tester, initiallySelected: const {'value-0'});
    await expand(tester);

    await tester.enterText(find.byType(TextField), 'Option 7');
    await tester.pumpAndSettle();

    // Selected rows are pinned above the matches, so a choice never scrolls
    // out of sight behind a query that doesn't match it.
    expect(row('Option 0'), findsOneWidget);
    expect(row('Option 7'), findsOneWidget);
    expect(row('Option 1'), findsNothing);
  });

  testWidgets('clear reset collapses an open searchable dropdown', (
    tester,
  ) async {
    final host = await pumpFacet(tester, initiallySelected: const {'value-0'});
    await expand(tester);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);

    host.rebuild(() => host.selected.clear());
    host.bumpReset();
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.search_rounded), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
  });

  testWidgets('an empty option list renders nothing at all', (tester) async {
    await pumpFacet(tester, optionCount: 0);

    expect(find.byType(InkWell), findsNothing);
    expect(find.text('Nationality'), findsNothing);
  });

  testWidgets('options render in the order given — the facet applies no sort', (
    tester,
  ) async {
    // Ordering is the backend's decision (pending a `displayPriority` field);
    // this pins that the widget never reorders on its own.
    await pumpFacet(tester, optionCount: 3);
    await expand(tester);

    final labels = tester
        .widgetList<Text>(
          find.descendant(of: find.byType(ListView), matching: find.byType(Text)),
        )
        .map((t) => t.data)
        .toList();
    expect(labels, ['Option 0', 'Option 1', 'Option 2']);
  });

  group('the indicator distinguishes single from multi select', () {
    testWidgets('multi renders checkboxes — empty box when unselected', (
      tester,
    ) async {
      await pumpFacet(tester, optionCount: 3, allowsMultiple: true);
      await expand(tester);

      expect(indicator(Icons.check_box_outline_blank_rounded), findsNWidgets(3));
      expect(indicator(Icons.circle_outlined), findsNothing);
      expect(indicator(Icons.check_circle_rounded), findsNothing);
    });

    testWidgets('multi renders a FILLED box for the selected row', (
      tester,
    ) async {
      await pumpFacet(
        tester,
        optionCount: 3,
        allowsMultiple: true,
        initiallySelected: const {'value-0'},
      );
      await expand(tester);

      expect(indicator(Icons.check_box_rounded), findsOneWidget);
      expect(indicator(Icons.check_box_outline_blank_rounded), findsNWidgets(2));
      expect(indicator(Icons.check_circle_rounded), findsNothing);
    });

    testWidgets('single keeps the circle it renders today, unselected', (
      tester,
    ) async {
      // Default (false) is deliberately what every pre-existing host renders.
      await pumpFacet(tester, optionCount: 3);
      await expand(tester);

      expect(indicator(Icons.circle_outlined), findsNWidgets(3));
      expect(indicator(Icons.check_box_outline_blank_rounded), findsNothing);
      expect(indicator(Icons.check_box_rounded), findsNothing);
    });

    testWidgets('single keeps the circle it renders today, selected', (
      tester,
    ) async {
      await pumpFacet(
        tester,
        optionCount: 3,
        initiallySelected: const {'value-0'},
      );
      await expand(tester);

      expect(indicator(Icons.check_circle_rounded), findsOneWidget);
      expect(indicator(Icons.circle_outlined), findsNWidgets(2));
      expect(indicator(Icons.check_box_rounded), findsNothing);
    });

    testWidgets('both modes paint the indicator from the same colours', (
      tester,
    ) async {
      // The real guarantee is structural: `_OptionRow` has ONE colour
      // expression, shared by both shapes, so there is no second place for the
      // multi indicator's fill to drift from the single one. This pins the
      // observable half of that — a future split into per-branch colours would
      // fail here.
      await pumpFacet(
        tester,
        optionCount: 3,
        allowsMultiple: true,
        initiallySelected: const {'value-0'},
      );
      await expand(tester);
      final multiSelected = indicatorColor(tester, Icons.check_box_rounded);
      final multiUnselected =
          indicatorColor(tester, Icons.check_box_outline_blank_rounded);

      // Tear the tree down first. Re-pumping the same widget type at the same
      // position REUSES the State, so the facet would still be expanded and the
      // collapsed chevron `expand` taps for would not exist.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      await pumpFacet(
        tester,
        optionCount: 3,
        initiallySelected: const {'value-0'},
      );
      await expand(tester);
      final singleSelected = indicatorColor(tester, Icons.check_circle_rounded);
      final singleUnselected = indicatorColor(tester, Icons.circle_outlined);

      expect(multiSelected, singleSelected);
      expect(multiUnselected, singleUnselected);
      // And selected stays legible against unselected by MORE than shape, in
      // both modes — the shapes already differ, the colours must too.
      expect(multiSelected, isNot(multiUnselected));
      expect(singleSelected, isNot(singleUnselected));
    });
  });
}
