import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/connectivity/connectivity_cubit.dart';
import 'package:qeran/core/design_system/widgets/qeran_error_state.dart';
import 'package:qeran/core/services/connectivity_service.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_active_filters.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_cubit.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_state.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_state_body.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_title_row.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Strings render as their keys, so assertions name the key they expect —
/// all but the daily limit's countdown, which has no room for a key.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {
        'discovery': {'daily_limit_reset_now': 'Now'},
      };
}

/// Real methods, so the state body's tear-offs (`cubit.refresh`, …) are
/// callable — a mock answers a tear-off with null.
class _FakeCubit extends Fake implements DiscoveryCubit {
  @override
  Stream<DiscoveryState> get stream => const Stream.empty();
  @override
  DiscoveryActiveFilters get activeFilters => DiscoveryActiveFilters.none;
  @override
  void ensurePrefetch() {}
  @override
  Future<void> refresh() async {}
  @override
  Future<void> resetSeen() async {}
  @override
  Future<void> retryPrefetch() async {}
  @override
  Future<void> loadInitial() async {}
}

/// The error state reads connectivity to tell offline from a server error.
class _OnlineConnectivity implements ConnectivityService {
  @override
  Future<bool> get isOnline async => true;
  @override
  Stream<bool> get onStatusChange => const Stream<bool>.empty();
}

DiscoveryLoaded _deck({int totalPages = 1, String? prefetchError}) =>
    DiscoveryLoaded(
      profiles: const [],
      currentIndex: 0,
      currentPage: 1,
      totalPages: totalPages,
      prefetchError: prefetchError,
    );

final _states = <String, DiscoveryState>{
  'loading': const DiscoveryLoading(),
  'waiting for more': _deck(totalPages: 2),
  'an empty deck': _deck(),
  'a failed load': const DiscoveryFailure(LocaleKeys.errors_generic),
  'a failed next page': _deck(totalPages: 2, prefetchError: 'errors.generic'),
  // Already past, so the countdown reads its one short word.
  'the daily limit': DiscoveryDailyLimit(
    DateTime.now().subtract(const Duration(minutes: 1)),
  ),
};

Future<void> _pump(WidgetTester tester, DiscoveryState state) async {
  final connectivity = ConnectivityCubit(service: _OnlineConnectivity());
  addTearDown(connectivity.close);
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<DiscoveryCubit>.value(value: _FakeCubit()),
              BlocProvider<ConnectivityCubit>.value(value: connectivity),
            ],
            child: Scaffold(
              body: DiscoveryStateBody(
                state: state,
                scrollOffset: ValueNotifier<double>(0),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  // The skeleton shimmers forever, so pump rather than settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Finder get _title => find.text(LocaleKeys.discovery_title);
Finder get _pill => find.text(LocaleKeys.discovery_filter_button);

InkWell _pillButton(WidgetTester tester) => tester.widget<InkWell>(
  find.ancestor(of: _pill, matching: find.byType(InkWell)).first,
);

/// Every state that isn't a loaded card keeps the Suggestions title where the
/// photo has it, on the canvas.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  for (final entry in _states.entries) {
    testWidgets('${entry.key}: the title, at the same spot', (tester) async {
      await _pump(tester, entry.value);

      expect(_title, findsOneWidget);
      expect(
        tester.getRect(find.byType(DiscoveryTitleRow)).bottom,
        DiscoveryTitleRow.extent,
      );
    });
  }

  testWidgets('loading: the pill is there but inert, at half strength', (
    tester,
  ) async {
    await _pump(tester, const DiscoveryLoading());

    expect(_pill, findsOneWidget);
    expect(_pillButton(tester).onTap, isNull);
    final dim = tester.widget<Opacity>(
      find.ancestor(of: _pill, matching: find.byType(Opacity)).first,
    );
    expect(dim.opacity, 0.5);
  });

  for (final key in ['waiting for more', 'an empty deck']) {
    testWidgets('$key: the pill opens the filters', (tester) async {
      await _pump(tester, _states[key]!);

      expect(_pillButton(tester).onTap, isNotNull);
    });
  }

  for (final key in [
    'a failed load',
    'a failed next page',
    'the daily limit',
  ]) {
    testWidgets('$key: the title only, no pill', (tester) async {
      await _pump(tester, _states[key]!);

      expect(_pill, findsNothing);
    });
  }

  testWidgets('a state\'s own content starts below the row', (tester) async {
    await _pump(tester, const DiscoveryFailure(LocaleKeys.errors_generic));

    expect(
      tester.getRect(find.byType(QeranErrorState)).top,
      greaterThanOrEqualTo(DiscoveryTitleRow.extent),
    );
  });
}
