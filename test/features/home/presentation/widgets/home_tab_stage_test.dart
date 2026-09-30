import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/home/presentation/home_tab_switcher.dart';
import 'package:qeran/features/home/presentation/widgets/home_tab_stage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

/// Counts how many times each tab got a fresh State — a remount means a
/// refetch.
final Map<int, int> _mounts = {};

class _Tab extends StatefulWidget {
  const _Tab(this.index);
  final int index;
  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  @override
  void initState() {
    super.initState();
    _mounts.update(widget.index, (n) => n + 1, ifAbsent: () => 1);
  }

  @override
  Widget build(BuildContext context) => Text('tab ${widget.index}');
}

/// Owns the switcher the way the shell does.
class _Host extends StatefulWidget {
  const _Host();
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  late final HomeTabSwitcher tabs = HomeTabSwitcher(vsync: this, initialTab: 0)
    ..addListener(() => setState(() {}));

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      HomeTabStage(tabs: tabs, tabBuilder: _Tab.new);
}

Future<HomeTabSwitcher> _pump(WidgetTester tester, Locale locale) async {
  _mounts.clear();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      startLocale: locale,
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: const _Host(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.state<_HostState>(find.byType(_Host)).tabs;
}

/// Where the incoming tab sits partway through a forward slide.
Future<double> _midSlideLeftOfTab1(WidgetTester tester, Locale locale) async {
  final tabs = await _pump(tester, locale);
  tabs.select(1);
  await tester.pump(); // the first-visit mount frame
  await tester.pump(const Duration(milliseconds: 60));
  final left = tester.getTopLeft(find.text('tab 1')).dx;
  await tester.pumpAndSettle();
  return left;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('shows the current tab and builds no other', (tester) async {
    await _pump(tester, const Locale('en'));

    expect(find.text('tab 0'), findsOneWidget);
    expect(find.text('tab 1', skipOffstage: false), findsNothing);
  });

  // Each tab fetches on its first visit and never again on later switches.
  testWidgets('a visited tab stays alive offstage', (tester) async {
    final tabs = await _pump(tester, const Locale('en'));

    tabs.select(1);
    await tester.pumpAndSettle();

    expect(find.text('tab 1'), findsOneWidget);
    expect(find.text('tab 0'), findsNothing);
    expect(find.text('tab 0', skipOffstage: false), findsOneWidget);

    tabs.select(0);
    await tester.pumpAndSettle();

    expect(find.text('tab 0'), findsOneWidget);
    expect(_mounts, {0: 1, 1: 1}, reason: 'switching back must not remount');
  });

  testWidgets('a forward slide enters from the right in English', (
    tester,
  ) async {
    expect(
      await _midSlideLeftOfTab1(tester, const Locale('en')),
      greaterThan(0),
    );
  });

  testWidgets('and from the left in Arabic', (tester) async {
    expect(await _midSlideLeftOfTab1(tester, const Locale('ar')), lessThan(0));
  });
}
