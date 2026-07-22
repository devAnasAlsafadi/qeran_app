import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:qeran/features/notifications/presentation/blocs/notification_badge_cubit.dart';
import 'package:qeran/features/subscriptions/domain/entities/current_subscription.dart';
import 'package:qeran/features/subscriptions/domain/usecases/get_current_subscription_usecase.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_page.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_profile.dart';
import 'package:qeran/features/discovery/domain/entities/like_outcome.dart';
import 'package:qeran/features/discovery/domain/usecases/fetch_discovery_page_usecase.dart';
import 'package:qeran/features/discovery/domain/usecases/like_profile_usecase.dart';
import 'package:qeran/features/discovery/domain/usecases/pass_profile_usecase.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_cubit.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_state.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_card.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

DiscoveryProfile _profile(String id) => DiscoveryProfile(
      id: id,
      name: 'Name-$id',
      age: 25,
      images: const [],
      matchingScore: 0,
      placements: const [],
    );

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

class _FakeFetch implements FetchDiscoveryPageUseCase {
  final List<DiscoveryProfile> _profiles;
  _FakeFetch(this._profiles);

  @override
  Future<Either<Failure, DiscoveryPage>> call({
    int page = 1,
    int pageSize = 10,
    Map<String, String>? filterParams,
  }) async =>
      Right(DiscoveryPage(
        profiles: _profiles,
        pageNumber: 1,
        pageSize: _profiles.length,
        totalCount: _profiles.length,
        totalPages: 1,
      ));
}

class _FakeLike implements LikeProfileUseCase {
  @override
  Future<Either<Failure, LikeOutcome>> call(String profileId) async =>
      const Right(LikeAccepted(likeId: '1'));
}

class _FakePass implements PassProfileUseCase {
  @override
  Future<Either<Failure, Unit>> call(String profileId) async =>
      const Right(unit);
}

class _FakeGetCurrent implements GetCurrentSubscriptionUseCase {
  @override
  Future<Either<Failure, CurrentSubscription?>> call() async =>
      const Right(null);
}

/// Real cubit wired to a no-op use case — it stays in its initial state (never
/// refreshed here), which is all `DiscoveryView` needs (it only `watch`es the
/// state to decide the upgrade banner). Supplies the provider the view now
/// requires so the widget tree builds under test.
class _FakeCurrentSubCubit extends CurrentSubscriptionCubit {
  _FakeCurrentSubCubit() : super(getCurrent: _FakeGetCurrent());
}

class _FakeGetNotifications extends Fake implements GetNotificationsUseCase {}

class _FakePrefs extends Fake implements SharedPrefService {}

/// `DiscoveryView` resolves the unread-badge cubit from GetIt and calls
/// `refresh()` on mount; a no-op refresh keeps its `false` state and never
/// touches the (unused) deps.
class _FakeNotificationBadgeCubit extends NotificationBadgeCubit {
  _FakeNotificationBadgeCubit()
      : super(getNotifications: _FakeGetNotifications(), prefs: _FakePrefs());
  @override
  Future<void> refresh() async {}
}

Future<void> _pumpView(
  WidgetTester tester,
  List<DiscoveryProfile> profiles,
) async {
  sl.registerFactory<DiscoveryCubit>(
    () => DiscoveryCubit(
      fetchPage: _FakeFetch(profiles),
      likeProfile: _FakeLike(),
      passProfile: _FakePass(),
    ),
  );
  // DiscoveryView resolves the unread-badge cubit from GetIt (app-scoped
  // singleton in prod). Register a no-op fake so the view builds under test.
  sl.registerLazySingleton<NotificationBadgeCubit>(
    () => _FakeNotificationBadgeCubit(),
  );
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
          home: BlocProvider<CurrentSubscriptionCubit>(
            create: (_) => _FakeCurrentSubCubit(),
            child: const Scaffold(body: DiscoveryView()),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── Unit: DiscoveryLoaded.next ──────────────────────────────────────────────
  group('DiscoveryLoaded.next', () {
    test('null when only one profile', () {
      final s = DiscoveryLoaded(
        profiles: [_profile('a')],
        currentIndex: 0,
        currentPage: 1,
        totalPages: 1,
      );
      expect(s.next, isNull);
    });

    test('returns second profile at index 0', () {
      final p1 = _profile('a');
      final p2 = _profile('b');
      final s = DiscoveryLoaded(
        profiles: [p1, p2],
        currentIndex: 0,
        currentPage: 1,
        totalPages: 1,
      );
      expect(s.next, equals(p2));
    });

    test('null when profile list is empty', () {
      final s = DiscoveryLoaded(
        profiles: const [],
        currentIndex: 0,
        currentPage: 1,
        totalPages: 1,
      );
      expect(s.next, isNull);
    });

    test('returns third profile when currentIndex is 1', () {
      final s = DiscoveryLoaded(
        profiles: [_profile('a'), _profile('b'), _profile('c')],
        currentIndex: 1,
        currentPage: 1,
        totalPages: 1,
      );
      expect(s.next, equals(_profile('c')));
    });

    test('null when currentIndex is the last slot', () {
      final s = DiscoveryLoaded(
        profiles: [_profile('a'), _profile('b')],
        currentIndex: 1,
        currentPage: 1,
        totalPages: 1,
      );
      expect(s.next, isNull);
    });
  });

  // ── Widget: peek layer ────────────────────────────────────────────────────
  group('next-card peek layer', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
    });

    setUp(() async => sl.reset());

    testWidgets('two DiscoveryImagePanel widgets when two profiles exist',
        (tester) async {
      await _pumpView(tester, [_profile('a'), _profile('b')]);
      expect(find.byType(DiscoveryImagePanel), findsNWidgets(2));
    });

    testWidgets('one DiscoveryImagePanel widget when only one profile',
        (tester) async {
      await _pumpView(tester, [_profile('a')]);
      expect(find.byType(DiscoveryImagePanel), findsOneWidget);
    });

    testWidgets('overlay icons render on the front card image panel — never on the peek card',
        (tester) async {
      await _pumpView(tester, [_profile('a'), _profile('b')]);
      // The active card (showOverlayActions: true) renders overlay actions, while the peek card
      // (showOverlayActions: false) suppresses DiscoveryImagePanel's internal overlay row.
      expect(
        find.byIcon(Icons.notifications_outlined),
        findsOneWidget,
        reason: 'front card image panel renders notifications icon',
      );
      expect(
        find.byIcon(Icons.tune_rounded),
        findsOneWidget,
        reason: 'front card image panel renders filter icon',
      );
    });

    testWidgets('peek Opacity(0.60) is wrapped in IgnorePointer',
        (tester) async {
      await _pumpView(tester, [_profile('a'), _profile('b')]);
      // _PeekCardLayer renders Opacity(opacity: 0.60). The active card
      // renders at full opacity, so this finder is unique to the peek.
      final peekOpacity = find.byWidgetPredicate(
        (w) => w is Opacity && (w.opacity - 0.60).abs() < 0.001,
      );
      expect(peekOpacity, findsOneWidget);
      // The peek Opacity must be inside IgnorePointer so it never blocks
      // gestures on the active card.
      expect(
        find.ancestor(of: peekOpacity, matching: find.byType(IgnorePointer)),
        findsAtLeastNWidgets(1),
      );
    });
  });
}
