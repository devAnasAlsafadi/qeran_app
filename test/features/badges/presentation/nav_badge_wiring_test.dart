import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_nav.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/badges/domain/entities/badge_tab_keys.dart';
import 'package:qeran/features/badges/domain/usecases/get_badges_usecase.dart';
import 'package:qeran/features/badges/domain/usecases/mark_tab_seen_usecase.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/features/matchmaker/home/presentation/widgets/matchmaker_bottom_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGet extends Fake implements GetBadgesUseCase {}

class _FakeMark extends Fake implements MarkTabSeenUseCase {}

class _FakeBadgesCubit extends BadgesCubit {
  _FakeBadgesCubit() : super(getBadges: _FakeGet(), markTabSeen: _FakeMark());
  @override
  Future<void> refresh() async {}
}

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

/// Only the MATCHMAKER nav is pumped directly — the user shell's items are
/// built inside `HomeScreen`, which drags in the whole app. The dot rules are
/// the same on both sides, and the user shell is covered on device.
Future<void> _pumpMatchmakerNav(WidgetTester tester) async {
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
            body: MatchmakerBottomNav(currentIndex: 0, onTap: (_) {}),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<QeranNavItem> _items(WidgetTester tester) =>
    tester.widget<QeranBottomNav>(find.byType(QeranBottomNav)).items;

void main() {
  late _FakeBadgesCubit badges;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  // `sl.reset()` is async — awaiting it matters, or the reset lands AFTER the
  // registration below and wipes it.
  setUp(() async {
    await sl.reset();
    badges = _FakeBadgesCubit();
    sl.registerLazySingleton<BadgesCubit>(() => badges);
  });

  tearDown(() async => sl.reset());

  testWidgets('a tab with unread carries a dot', (tester) async {
    badges.applyUpdate(BadgeTabKeys.cases, 2);
    await _pumpMatchmakerNav(tester);

    final cases = _items(tester)[2];
    expect(cases.badgeCount, 2);
    expect(cases.badgeIsDot, isTrue);
  });

  testWidgets('a tab with nothing unread carries none', (tester) async {
    await _pumpMatchmakerNav(tester);

    expect(_items(tester)[2].badgeCount, 0);
  });

  // The count is passed through rather than collapsed to a flag: it is what
  // decides whether the dot shows at all, and it leaves the door open to
  // numbers without a design-system change.
  testWidgets('the real count reaches the item, not a synthesised 1', (
    tester,
  ) async {
    badges.applyUpdate(BadgeTabKeys.users, 12);
    await _pumpMatchmakerNav(tester);

    expect(_items(tester)[1].badgeCount, 12);
  });

  // Identity rule — gold, never the danger token.
  testWidgets('dots are gold', (tester) async {
    badges.applyUpdate(BadgeTabKeys.conversations, 1);
    await _pumpMatchmakerNav(tester);

    final item = _items(tester)[3];
    expect(item.badgeColor, QeranColors.gold);
    expect(item.badgeColor, isNot(QeranColors.danger));
  });

  // "Don't paint what the backend can't source": both are documented as
  // permanently zero, so they must never be wired at all — not merely happen
  // to read zero today.
  testWidgets('dashboard and explore are never wired', (tester) async {
    badges
      ..applyUpdate(BadgeTabKeys.dashboard, 5)
      ..applyUpdate(BadgeTabKeys.explore, 5);
    await _pumpMatchmakerNav(tester);

    final items = _items(tester);
    expect(items[0].badgeCount, isNull, reason: 'dashboard');
    expect(items[4].badgeCount, isNull, reason: 'explore');
  });

  testWidgets('the nav follows the cubit without being rebuilt by a parent', (
    tester,
  ) async {
    await _pumpMatchmakerNav(tester);
    expect(_items(tester)[2].badgeCount, 0);

    badges.applyUpdate(BadgeTabKeys.cases, 4);
    await tester.pumpAndSettle();

    expect(_items(tester)[2].badgeCount, 4);
  });
}
