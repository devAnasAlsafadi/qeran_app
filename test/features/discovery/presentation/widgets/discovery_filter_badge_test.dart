import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_count_badge.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_active_filters.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_cubit.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_state.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_state_body.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_title_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CopyLoader extends AssetLoader {
  const _CopyLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {
        'discovery': {
          'title': 'Suggestions',
          'filter_button': 'Edit filters',
          'filter_button_active_a11y': 'Edit filters, active filters: {count}',
        },
      };
}

class _FakeCubit extends Fake implements DiscoveryCubit {
  _FakeCubit(this.activeFilters);
  @override
  final DiscoveryActiveFilters activeFilters;
  @override
  Stream<DiscoveryState> get stream => const Stream.empty();
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      assetLoader: const _CopyLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: Scaffold(body: child),
        ),
      ),
    ),
  );
  // The skeleton shimmers forever, so pump rather than settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Widget _row({required int count, VoidCallback? onTap}) => DiscoveryTitleRow(
  onPhoto: false,
  activeFilterCount: count,
  onEditFilters: onTap,
);

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('no filter active: no badge, and the pill reads as before', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _row(count: 0, onTap: () {}));

    expect(find.byType(QeranCountBadge), findsNothing);
    expect(find.bySemanticsLabel('Edit filters'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('filters active: the badge carries their number', (tester) async {
    await _pump(tester, _row(count: 3, onTap: () {}));

    expect(
      find.descendant(
        of: find.byType(QeranCountBadge),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a screen reader hears one button that says what it counts', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var opened = 0;
    await _pump(tester, _row(count: 3, onTap: () => opened++));

    final pill = find.bySemanticsLabel('Edit filters, active filters: 3');
    expect(
      tester.getSemantics(pill),
      matchesSemantics(
        label: 'Edit filters, active filters: 3',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(find.text('Edit filters'));
    expect(opened, 1);
    semantics.dispose();
  });

  testWidgets('while the deck reloads, the badge dims with the inert pill', (
    tester,
  ) async {
    await _pump(tester, _row(count: 2));

    final dim = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.byType(QeranCountBadge),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(dim.opacity, 0.5);
  });

  testWidgets('the count comes from the filters applied to the deck', (
    tester,
  ) async {
    // Two questions: a range (two keys) and a multi-select (two values).
    final cubit = _FakeCubit(
      DiscoveryActiveFilters(
        query: const {
          'RangeFrom[5]': '160',
          'RangeTo[5]': '180',
          'QuestionFilters[7]': 'SA,KW',
        },
      ),
    );
    await _pump(
      tester,
      BlocProvider<DiscoveryCubit>.value(
        value: cubit,
        child: DiscoveryStateBody(
          state: const DiscoveryLoading(),
          scrollOffset: ValueNotifier<double>(0),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(QeranCountBadge),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
  });
}
