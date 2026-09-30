import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/widgets/connectivity_banner_host.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Strings render as their keys, so assertions name the key they expect.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

/// A page with a bar of [barHeight] and the slot under it.
class _Page extends StatelessWidget {
  const _Page({this.barHeight = 64, this.attaches = true});

  final double barHeight;

  /// False is a shared widget's slot on a page that keeps the overlay.
  final bool attaches;

  @override
  Widget build(BuildContext context) {
    final page = Scaffold(
      body: Column(
        children: [
          SizedBox(height: barHeight),
          const ConnectivityBannerSlot(),
          const Expanded(child: SizedBox.expand()),
        ],
      ),
    );
    return attaches ? AttachedConnectivityBanner(child: page) : page;
  }
}

final _nav = GlobalKey<NavigatorState>();
final _offline = ValueNotifier<bool>(true);

Future<void> _pump(WidgetTester tester, Widget home) async {
  _offline.value = true;
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          navigatorKey: _nav,
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          builder: (_, child) => ValueListenableBuilder<bool>(
            valueListenable: _offline,
            builder: (_, offline, _) =>
                ConnectivityBannerHost(offline: offline, child: child!),
          ),
          home: home,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _banner => find.ancestor(
  of: find.text(LocaleKeys.errors_offline),
  matching: find.byType(Material),
);

/// The one banner on screen, wherever it is.
Rect _shown(WidgetTester tester) {
  expect(find.text(LocaleKeys.errors_offline), findsOneWidget);
  return tester.getRect(_banner.first);
}

Future<void> _push(WidgetTester tester, Widget page) async {
  _nav.currentState!.push(MaterialPageRoute<void>(builder: (_) => page));
  await tester.pumpAndSettle();
}

Future<void> _pop(WidgetTester tester) async {
  _nav.currentState!.pop();
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('a page that keeps the overlay: the banner covers its top', (
    tester,
  ) async {
    await _pump(tester, const Scaffold());

    expect(_shown(tester).top, 0);
  });

  testWidgets('online, there is no banner anywhere', (tester) async {
    await _pump(tester, const _Page());
    _offline.value = false;
    await tester.pumpAndSettle();

    expect(find.text(LocaleKeys.errors_offline), findsNothing);
  });

  testWidgets('a page that attaches it: under its bar, and no overlay', (
    tester,
  ) async {
    await _pump(tester, const _Page());

    expect(_shown(tester).top, 64);
  });

  testWidgets('a page pushed on top that keeps the overlay gets it back', (
    tester,
  ) async {
    await _pump(tester, const _Page());

    await _push(tester, const Scaffold());
    expect(_shown(tester).top, 0);

    await _pop(tester);
    expect(_shown(tester).top, 64);
  });

  testWidgets('one attaching page over another: under the top one\'s bar', (
    tester,
  ) async {
    await _pump(tester, const _Page());

    await _push(tester, const _Page(barHeight: 80));
    expect(_shown(tester).top, 80);

    await _pop(tester);
    expect(_shown(tester).top, 64);
  });

  // The chat header is the matchmaker app's too; its chat keeps the overlay.
  testWidgets('a slot on a page that has not opted in stays empty', (
    tester,
  ) async {
    await _pump(tester, const _Page(attaches: false));

    expect(_shown(tester).top, 0);
  });

  testWidgets('attached, it leaves the status-bar inset to the bar', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(top: 72);
    addTearDown(tester.view.resetPadding);

    await _pump(tester, const Scaffold());
    final over = _shown(tester).height;
    await _pump(tester, const _Page());
    final under = _shown(tester).height;

    // 72 physical pixels at the test view's ratio of 3.
    expect(over - under, 24);
  });
}
