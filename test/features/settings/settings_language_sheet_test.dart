import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/widgets/locale_rebuild_scope.dart';
import 'package:qeran/features/settings/presentation/widgets/settings_language_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The language sheet switches the locale that destroys the very screen it was
/// opened from.
///
/// `LocaleRebuildScope` keys a shell slot's content on the language code, so
/// applying a new locale discards the tab subtree — including the settings /
/// account screen whose context opened the sheet. Anything the sheet still
/// reads off that context after the switch is a lookup on a deactivated
/// element. Both shells mount their tabs this way, so the trap is identical in
/// the user app and the matchmaker app; this harness stands in for both.

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

/// Stands in for the profile / account screen: it lives inside the scope, so
/// the locale switch tears it down, and it is the context the sheet is opened
/// from.
class _HostScreen extends StatelessWidget {
  const _HostScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => showSettingsLanguageSheet(context),
          child: const Text('open'),
        ),
      ),
    );
  }
}

Future<void> _pumpApp(WidgetTester tester, {required Locale start}) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      startLocale: start,
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          // Exactly how both shells mount their tab content.
          home: const LocaleRebuildScope(child: _HostScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Opens the sheet and taps one of the two options.
Future<void> _switchTo(WidgetTester tester, String native) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();

  expect(find.text(native), findsOneWidget, reason: 'sheet should be open');

  await tester.tap(find.text(native));
  // The sheet's exit transition runs WHILE the locale switch rebuilds the tree
  // underneath it — this is the window the crash lived in, so pump through it
  // frame by frame rather than jumping to settled.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('ar -> en switches without touching a torn-down ancestor', (
    tester,
  ) async {
    await _pumpApp(tester, start: const Locale('ar'));

    await _switchTo(tester, 'English');

    expect(tester.takeException(), isNull);
    expect(
      Localizations.localeOf(tester.element(find.byType(Scaffold))),
      const Locale('en'),
    );
  });

  testWidgets('en -> ar switches without touching a torn-down ancestor', (
    tester,
  ) async {
    await _pumpApp(tester, start: const Locale('en'));

    await _switchTo(tester, 'العربية');

    expect(tester.takeException(), isNull);
    expect(
      Localizations.localeOf(tester.element(find.byType(Scaffold))),
      const Locale('ar'),
    );
  });

  testWidgets('re-picking the active language is a no-op close', (
    tester,
  ) async {
    await _pumpApp(tester, start: const Locale('ar'));

    await _switchTo(tester, 'العربية');

    expect(tester.takeException(), isNull);
    expect(
      Localizations.localeOf(tester.element(find.byType(Scaffold))),
      const Locale('ar'),
    );
    // Sheet is gone and the host survived.
    expect(find.text('English'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
