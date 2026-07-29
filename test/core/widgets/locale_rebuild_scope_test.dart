import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/widgets/locale_rebuild_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Switching language has to reload what the SERVER translated for us, not
/// just repaint the strings the app owns.
///
/// The shells keep their tabs mounted, so a tab that fetched in Arabic would
/// keep showing Arabic chips and section titles after a switch to English
/// until the user pulled to refresh it by hand. This scope is what discards
/// that subtree so its cubits are built again and fetch again.

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

/// Stands in for a screen that fetches on mount: it counts how many times a
/// fresh State was created.
class _FetchingScreen extends StatefulWidget {
  const _FetchingScreen();
  @override
  State<_FetchingScreen> createState() => _FetchingScreenState();
}

int _mounts = 0;

class _FetchingScreenState extends State<_FetchingScreen> {
  @override
  void initState() {
    super.initState();
    _mounts++;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Same screen WITHOUT the scope, to prove the scope is what does the work.
Future<void> _pump(WidgetTester tester, {required bool scoped}) async {
  _mounts = 0;
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      startLocale: const Locale('ar'),
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: scoped
              ? const LocaleRebuildScope(child: _FetchingScreen())
              : const _FetchingScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _switchToEnglish(WidgetTester tester) async {
  final ctx = tester.element(find.byType(MaterialApp));
  await ctx.setLocale(const Locale('en'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('a language switch rebuilds the subtree from scratch', (
    tester,
  ) async {
    await _pump(tester, scoped: true);
    expect(_mounts, 1);

    await _switchToEnglish(tester);

    // A NEW State — so the screen's cubits are new too, and refetch under the
    // new Accept-Language.
    expect(_mounts, 2);
  });

  testWidgets('without it the screen just keeps its stale state', (
    tester,
  ) async {
    await _pump(tester, scoped: false);
    expect(_mounts, 1);

    await _switchToEnglish(tester);

    // This is the bug: same State, so whatever it fetched in Arabic stays.
    expect(_mounts, 1);
  });

  testWidgets('rebuilding for other reasons does not churn the subtree', (
    tester,
  ) async {
    await _pump(tester, scoped: true);

    await tester.pump();
    await tester.pump();

    expect(_mounts, 1);
  });
}
