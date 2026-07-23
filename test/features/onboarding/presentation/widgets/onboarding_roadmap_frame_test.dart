import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/onboarding/presentation/widgets/frames/onboarding_roadmap_frame.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('lays out without IntrinsicHeight or overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ar')],
        path: 'assets/translations',
        assetLoader: const _StubAssetLoader(),
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: OnboardingRoadmapFrame(
              onFinish: () {},
              dotCount: 3,
              activeDot: 2,
              onDot: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(IntrinsicHeight), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
