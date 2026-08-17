import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/explore/presentation/widgets/matchmaker_explore_empty_results.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Two variants, mirroring the user app's `DiscoveryEmptyView`. "Narrowed" spans
/// the filter sheet, the search field AND the gender segment — any of the three
/// can empty the list, and the clear action drops all of them.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {
        'matchmaker': {
          'explore_no_results_title': 'No profiles found',
          'explore_no_results_message': 'Try a different search.',
          'explore_no_results_filtered_title': 'No matches for your filters',
          'explore_no_results_filtered_message': 'Try widening or clearing them.',
          'explore_edit_filters': 'Edit filters',
          'explore_clear_filters': 'Clear filters',
        },
      };
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<void> pump(
    WidgetTester tester, {
    required bool hasActiveFilters,
    VoidCallback? onEditFilters,
    VoidCallback? onClearFilters,
  }) async {
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
              body: MatchmakerExploreEmptyResults(
                onRefresh: () async {},
                hasActiveFilters: hasActiveFilters,
                onEditFilters: onEditFilters,
                onClearFilters: onClearFilters,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('unfiltered: plain copy, no way out offered', (tester) async {
    await pump(tester, hasActiveFilters: false);

    expect(find.text('No profiles found'), findsOneWidget);
    expect(find.text('Edit filters'), findsNothing);
    expect(find.text('Clear filters'), findsNothing);
    expect(find.byIcon(Icons.person_search_outlined), findsOneWidget);
  });

  testWidgets('narrowed: filtered copy plus BOTH exits', (tester) async {
    await pump(
      tester,
      hasActiveFilters: true,
      onEditFilters: () {},
      onClearFilters: () {},
    );

    expect(find.text('No matches for your filters'), findsOneWidget);
    expect(find.text('Try widening or clearing them.'), findsOneWidget);
    expect(find.text('Edit filters'), findsOneWidget);
    expect(find.text('Clear filters'), findsOneWidget);
    expect(find.byIcon(Icons.filter_alt_off_outlined), findsOneWidget);
  });

  testWidgets('edit-filters fires its callback', (tester) async {
    var edited = 0;
    await pump(
      tester,
      hasActiveFilters: true,
      onEditFilters: () => edited++,
      onClearFilters: () {},
    );

    await tester.tap(find.text('Edit filters'));
    await tester.pump();

    expect(edited, 1);
  });

  testWidgets('clear-filters fires its callback', (tester) async {
    var cleared = 0;
    await pump(
      tester,
      hasActiveFilters: true,
      onEditFilters: () {},
      onClearFilters: () => cleared++,
    );

    await tester.tap(find.text('Clear filters'));
    await tester.pump();

    expect(cleared, 1);
  });

  testWidgets('narrowed but callbacks missing → copy changes, no dead buttons', (
    tester,
  ) async {
    // `_showActions` requires all three. A half-wired host gets the honest copy
    // without buttons that do nothing.
    await pump(tester, hasActiveFilters: true);

    expect(find.text('No matches for your filters'), findsOneWidget);
    expect(find.text('Edit filters'), findsNothing);
    expect(find.text('Clear filters'), findsNothing);
  });
}
