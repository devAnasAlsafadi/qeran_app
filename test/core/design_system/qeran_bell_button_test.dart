import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_bell_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_count_badge.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/badges/domain/entities/badge_tab_keys.dart';
import 'package:qeran/features/badges/domain/usecases/get_badges_usecase.dart';
import 'package:qeran/features/badges/domain/usecases/mark_tab_seen_usecase.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/features/matchmaker/shared/presentation/widgets/matchmaker_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Strings render as their keys, so assertions name the key they expect.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

class _FakeGetBadges extends Fake implements GetBadgesUseCase {}

class _FakeMarkTabSeen extends Fake implements MarkTabSeenUseCase {}

Future<void> _pump(WidgetTester tester, Widget child) async {
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
          home: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('no count while nothing is unread; a tap is the caller\'s', (
    tester,
  ) async {
    var taps = 0;
    await _pump(tester, QeranBellButton(count: 0, onTap: () => taps++));

    expect(find.byType(QeranCountBadge), findsNothing);
    await tester.tap(find.byType(QeranBellButton));
    expect(taps, 1);
  });

  testWidgets('carries the unread count, capped at 99+', (tester) async {
    await _pump(tester, QeranBellButton(count: 140, onTap: () {}));

    expect(find.text('99+'), findsOneWidget);
  });

  // One widget so the two apps cannot drift: the matchmaker's app bar must
  // draw this bell, fed by the same server count, not a copy of its own.
  group('the matchmaker app bar', () {
    late BadgesCubit badges;

    setUp(() {
      badges = BadgesCubit(
        getBadges: _FakeGetBadges(),
        markTabSeen: _FakeMarkTabSeen(),
      );
      sl.registerSingleton<BadgesCubit>(badges);
    });

    tearDown(() async {
      await sl.reset();
      await badges.close();
    });

    testWidgets('draws the shared bell with the server\'s count', (
      tester,
    ) async {
      badges.applyUpdate(BadgeTabKeys.notifications, 4);
      await _pump(
        tester,
        const CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: kToolbarHeight,
                child: MatchmakerAppBar(title: 'Dashboard'),
              ),
            ),
          ],
        ),
      );

      final bell = tester.widget<QeranBellButton>(find.byType(QeranBellButton));
      expect(bell.count, 4);
      expect(find.text('4'), findsOneWidget);
    });
  });
}
