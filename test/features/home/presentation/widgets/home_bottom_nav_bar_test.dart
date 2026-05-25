import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Localization stub ─────────────────────────────────────────────────────────

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildNav({
  int currentIndex = 0,
  ValueChanged<int>? onTabSelected,
}) {
  return EasyLocalization(
    supportedLocales: const [Locale('ar')],
    path: 'assets/translations',
    assetLoader: const _StubAssetLoader(),
    child: Builder(
      builder: (ctx) => MaterialApp(
        locale: ctx.locale,
        supportedLocales: ctx.supportedLocales,
        localizationsDelegates: ctx.localizationDelegates,
        home: Scaffold(
          bottomNavigationBar: HomeBottomNavBar(
            currentIndex: currentIndex,
            onTabSelected: onTabSelected ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('HomeBottomNavBar', () {
    testWidgets('renders all 4 tab icons', (tester) async {
      await tester.pumpWidget(_buildNav());
      await tester.pumpAndSettle();

      // Tab 0 (active) → filled icon; tabs 1-3 → outlined icons.
      expect(find.byIcon(Icons.diamond), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('tapping each inactive tab fires callback with correct index',
        (tester) async {
      final tapped = <int>[];
      await tester.pumpWidget(
        _buildNav(currentIndex: 0, onTabSelected: tapped.add),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.favorite_border)); // tab 1
      await tester.tap(find.byIcon(Icons.chat_bubble_outline)); // tab 2
      await tester.tap(find.byIcon(Icons.person_outline)); // tab 3
      await tester.pump();

      expect(tapped, orderedEquals([1, 2, 3]));
    });

    testWidgets('active tab icon uses primary color after animation settles',
        (tester) async {
      await tester.pumpWidget(_buildNav(currentIndex: 1));
      await tester.pumpAndSettle(); // let TweenAnimationBuilder reach t = 1.0

      // Tab 1 active → filled Icons.favorite rendered with primary color.
      final icon = tester.widget<Icon>(find.byIcon(Icons.favorite));
      expect(icon.color, AppColors.primary);
    });

    testWidgets('inactive tab icon uses secondary color after animation settles',
        (tester) async {
      await tester.pumpWidget(_buildNav(currentIndex: 0));
      await tester.pumpAndSettle();

      // Tab 3 (profile) is inactive → outlined icon, textSecondary color.
      final icon = tester.widget<Icon>(find.byIcon(Icons.person_outline));
      expect(icon.color, AppColors.textSecondary);
    });

    testWidgets('active pill background is non-transparent', (tester) async {
      await tester.pumpWidget(_buildNav(currentIndex: 2));
      await tester.pumpAndSettle();

      // The AnimatedContainer for the active tab (index 2) carries a tinted
      // BoxDecoration. We confirm at least one exists with a non-transparent
      // background color.
      final activePill = find.byWidgetPredicate((w) {
        if (w is! AnimatedContainer) return false;
        final col = (w.decoration as BoxDecoration?)?.color;
        return col != null && col != Colors.transparent && col.a > 0;
      });
      expect(activePill, findsOneWidget,
          reason: 'exactly one active-pill background expected');
    });

    testWidgets('no overflow at 360 × 780 logical pixels', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildNav());
      await tester.pumpAndSettle();
      // If any RenderFlex overflow occurs Flutter throws during layout.
    });
  });
}
