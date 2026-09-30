import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_app_bar.dart';
import 'package:qeran/core/widgets/locale_rebuild_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The back chevron answers one question: can THIS screen go back? Asking the
/// navigator instead answers "can anything be popped", which is true for a
/// shell tab whenever another screen sits on top of it.
///
/// The matchmaker switches language from Account, a screen pushed over her
/// shell. The switch rebuilds the tabs underneath (`LocaleRebuildScope`), and
/// a tab that asked the navigator then drew a chevron. Nothing rebuilt it on
/// the way back, so the Dashboard kept a chevron that went nowhere.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

final _navigator = GlobalKey<NavigatorState>();

/// A shell tab: its content in a `LocaleRebuildScope`, as both shells mount
/// theirs.
Future<void> _pumpTab(WidgetTester tester) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      startLocale: const Locale('en'),
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          navigatorKey: _navigator,
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: const LocaleRebuildScope(
            child: Scaffold(appBar: QeranAppBar(title: 'Dashboard')),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Account, pushed over the tab.
Future<void> _pushScreen(WidgetTester tester) async {
  _navigator.currentState!.push(
    MaterialPageRoute<void>(
      builder: (_) => const Scaffold(appBar: QeranAppBar(title: 'Account')),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _switchToArabic(WidgetTester tester) async {
  await tester.element(find.byType(MaterialApp)).setLocale(const Locale('ar'));
  await tester.pumpAndSettle();
}

Future<void> _goBack(WidgetTester tester) async {
  _navigator.currentState!.pop();
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets(
    'a tab rebuilt under a pushed screen has no chevron back on top',
    (tester) async {
      await _pumpTab(tester);
      await _pushScreen(tester);

      await _switchToArabic(tester);
      await _goBack(tester);

      expect(
        _navigator.currentState!.canPop(),
        isFalse,
        reason: 'only the tab',
      );
      expect(find.byType(QeranBackButton), findsNothing);
    },
  );

  testWidgets('the pushed screen keeps its chevron through the switch', (
    tester,
  ) async {
    await _pumpTab(tester);
    await _pushScreen(tester);

    await _switchToArabic(tester);

    // Only the top screen is on stage; the tab under it is offstage.
    expect(find.byType(QeranBackButton), findsOneWidget);
  });

  testWidgets('a tab never shows one while a screen sits on top of it', (
    tester,
  ) async {
    await _pumpTab(tester);
    await _pushScreen(tester);
    await _switchToArabic(tester);

    // Offstage included: the covered tab is still built, just not painted.
    expect(
      find.byType(QeranBackButton, skipOffstage: false),
      findsOneWidget,
      reason: 'the pushed screen has the only chevron',
    );
  });
}
