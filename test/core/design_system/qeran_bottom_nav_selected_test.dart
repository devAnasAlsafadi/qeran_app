import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_nav.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/badges/domain/entities/badge_counts.dart';
import 'package:qeran/features/badges/domain/usecases/get_badges_usecase.dart';
import 'package:qeran/features/badges/domain/usecases/mark_tab_seen_usecase.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/features/home/presentation/widgets/home_nav_items.dart';
import 'package:qeran/features/matchmaker/home/presentation/widgets/matchmaker_bottom_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Run 8 (the client): the selected tab stays in its own place inside the
/// bar — a gold disc behind its filled wine icon, its label wine and bold —
/// so nothing rises above the island or is cut by its edges. Both apps.

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

/// Either app's nav, at [index], on a 360-wide phone; a tap moves it.
Widget _userNav(BuildContext context, int index, ValueChanged<int> onTap) =>
    QeranBottomNav(
      items: buildHomeNavItems(context, const BadgeCounts.empty()),
      currentIndex: index,
      onTap: onTap,
    );

Widget _herNav(BuildContext context, int index, ValueChanged<int> onTap) =>
    MatchmakerBottomNav(currentIndex: index, onTap: onTap);

typedef _Nav = Widget Function(BuildContext, int, ValueChanged<int>);

Future<void> _pump(WidgetTester tester, String lang, _Nav nav, int at) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  var index = at;
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: [Locale(lang)],
      startLocale: Locale(lang),
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              bottomNavigationBar: nav(
                context,
                index,
                (i) => setState(() => index = i),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<QeranNavItem> _items(WidgetTester tester) =>
    tester.widget<QeranBottomNav>(find.byType(QeranBottomNav)).items;

Rect _disc(WidgetTester tester) =>
    tester.getRect(find.byKey(QeranBottomNav.discKey));

/// The disc lies wholly inside the island, centred on the selected tab: over
/// its label, and level with every other tab's icon (no lift).
void _expectInPlace(WidgetTester tester, int selected) {
  final bar = tester.getRect(find.byKey(QeranBottomNav.barKey));
  final disc = _disc(tester);
  expect(bar.contains(disc.topLeft) && bar.contains(disc.bottomRight), isTrue);
  final items = _items(tester);
  final label = tester.getRect(find.text(items[selected].label));
  expect(disc.center.dx, moreOrLessEquals(label.center.dx, epsilon: 0.5));
  // The label under it, whole: not overlapped, squeezed or pushed out.
  expect(label.top, greaterThanOrEqualTo(disc.bottom));
  expect(label.bottom, lessThanOrEqualTo(bar.bottom));
  final text = tester.widget<Text>(find.text(items[selected].label));
  final whole = TextPainter(
    text: TextSpan(text: text.data, style: text.style),
    textDirection: TextDirection.ltr,
  )..layout();
  addTearDown(whole.dispose);
  expect(label.height, moreOrLessEquals(whole.height, epsilon: 0.5));
  for (var i = 0; i < items.length; i++) {
    if (i == selected) continue;
    final icon = tester.getCenter(find.byIcon(items[i].outlineIcon));
    expect(disc.center.dy, moreOrLessEquals(icon.dy, epsilon: 0.5));
  }
}

double _opacity(WidgetTester tester, IconData icon) => tester
    .widget<FadeTransition>(
      find
          .ancestor(
            of: find.byIcon(icon),
            matching: find.byType(FadeTransition),
          )
          .first,
    )
    .opacity
    .value;

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() async {
    await sl.reset();
    sl.registerLazySingleton<BadgesCubit>(_FakeBadgesCubit.new);
  });

  tearDown(() async => sl.reset());

  for (final (app, nav, count) in [
    ('member', _userNav, 4),
    ('her', _herNav, 5),
  ]) {
    for (final lang in const ['ar', 'en']) {
      testWidgets('$app nav: every selected tab sits in place [$lang]', (
        tester,
      ) async {
        for (var i = 0; i < count; i++) {
          await _pump(tester, lang, nav, i);
          _expectInPlace(tester, i);
        }
      });

      testWidgets('$app nav: the selected tab is coloured, the rest muted '
          '[$lang]', (tester) async {
        await _pump(tester, lang, nav, 0);
        final items = _items(tester);
        for (var i = 0; i < count; i++) {
          final on = i == 0;
          final label = tester.widget<Text>(find.text(items[i].label)).style!;
          expect(label.color, on ? QeranColors.wine : QeranColors.inkMuted);
          expect(label.fontWeight, on ? FontWeight.w700 : FontWeight.w500);
          expect(_opacity(tester, items[i].filledIcon), on ? 1 : 0);
          expect(_opacity(tester, items[i].outlineIcon), on ? 0 : 1);
        }
        final filled = tester.widget<Icon>(find.byIcon(items[0].filledIcon));
        expect(filled.color, QeranColors.wine);
      });
    }

    testWidgets('$app nav: a tap moves the disc, never out of the bar', (
      tester,
    ) async {
      await _pump(tester, 'ar', nav, 0);
      final bar = tester.getRect(find.byKey(QeranBottomNav.barKey));
      await tester.tap(find.text(_items(tester)[count - 1].label));
      for (var frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 80));
        final disc = _disc(tester);
        expect(disc.top, greaterThanOrEqualTo(bar.top));
        expect(disc.bottom, lessThanOrEqualTo(bar.bottom));
      }
      await tester.pumpAndSettle();
      _expectInPlace(tester, count - 1);
    });
  }
}
