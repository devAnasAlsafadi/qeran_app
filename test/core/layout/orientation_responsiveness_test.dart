import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_nav.dart';
import 'package:qeran/features/auth/presentation/widgets/auth_hero_scaffold.dart';
import 'package:qeran/features/likes/presentation/screens/match_success_screen.dart';
import 'package:qeran/features/onboarding/presentation/widgets/frames/onboarding_essence_frame.dart';
import 'package:qeran/features/onboarding/presentation/widgets/frames/onboarding_mediation_frame.dart';
import 'package:qeran/features/onboarding/presentation/widgets/frames/onboarding_roadmap_frame.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

Widget _localizedApp(Widget home) {
  return EasyLocalization(
    supportedLocales: const [Locale('ar')],
    path: 'assets/translations',
    assetLoader: const _StubAssetLoader(),
    child: Builder(
      builder: (context) => MaterialApp(
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        home: home,
      ),
    ),
  );
}

Future<void> _setLandscape(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  final onboardingFrames = <String, Widget>{
    'essence': OnboardingEssenceFrame(
      dotCount: 3,
      activeDot: 0,
      onDot: (_) {},
      onNext: () {},
    ),
    'mediation': OnboardingMediationFrame(
      dotCount: 3,
      activeDot: 1,
      onDot: (_) {},
      onNext: () {},
      onSearch: () {},
    ),
    'roadmap': OnboardingRoadmapFrame(
      dotCount: 3,
      activeDot: 2,
      onDot: (_) {},
      onFinish: () {},
    ),
  };

  for (final entry in onboardingFrames.entries) {
    testWidgets('${entry.key} onboarding frame has no landscape overflow', (
      tester,
    ) async {
      await _setLandscape(tester);
      await tester.pumpWidget(_localizedApp(entry.value));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
    });
  }

  testWidgets('auth shell switches to a scrollable landscape split', (
    tester,
  ) async {
    await _setLandscape(tester);
    await tester.pumpWidget(
      _localizedApp(
        AuthHeroScaffold(
          showBack: true,
          showLanguageSwitch: true,
          children: List.generate(
            12,
            (index) => SizedBox(height: 48, child: Text('Field $index')),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(Row), findsWidgets);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('bottom navigation uses compact landscape height', (
    tester,
  ) async {
    await _setLandscape(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: QeranBottomNav(
            items: const [
              QeranNavItem(
                outlineIcon: Icons.home_outlined,
                filledIcon: Icons.home,
                label: 'Home',
              ),
              QeranNavItem(
                outlineIcon: Icons.favorite_outline,
                filledIcon: Icons.favorite,
                label: 'Likes',
              ),
            ],
            currentIndex: 0,
            onTap: (_) {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox &&
            widget.height == QeranBottomNav.compactLandscapeHeight,
      ),
      findsOneWidget,
    );
  });

  testWidgets('match success content remains scrollable in landscape', (
    tester,
  ) async {
    await _setLandscape(tester);
    await tester.pumpWidget(
      _localizedApp(
        const MatchSuccessScreen(
          args: MatchSuccessArgs(otherName: 'A deliberately long name'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
