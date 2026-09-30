import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_dashed_ring.dart';
import 'package:qeran/features/community/presentation/screens/community_placeholder_screen.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Strings render as their keys, so the assertions name the key they expect.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('the tab title over a dashed frame for the feed', (tester) async {
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
            home: const Scaffold(body: CommunityPlaceholderScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(LocaleKeys.home_nav_community), findsOneWidget);
    expect(find.byType(QeranDashedRing), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(QeranDashedRing),
        matching: find.text(LocaleKeys.community_placeholder_body),
      ),
      findsOneWidget,
    );
  });
}
