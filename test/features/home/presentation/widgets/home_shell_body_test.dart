import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/widgets/connectivity_banner_host.dart';
import 'package:qeran/features/badges/domain/entities/badge_counts.dart';
import 'package:qeran/features/chat/presentation/blocs/my_matchmaker_cubit.dart';
import 'package:qeran/features/home/presentation/widgets/home_shell_body.dart';
import 'package:qeran/features/home/presentation/widgets/shell_top_bar.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shell_top_bar_host.dart';

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

const _tabsKey = Key('tabs');

/// The shell body under the app's banner host, as the app mounts it.
Future<void> _pump(WidgetTester tester, {required bool offline}) async {
  final matchmaker = await matchmakerCubit(null);
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
          builder: (_, child) =>
              ConnectivityBannerHost(offline: offline, child: child!),
          home: BlocProvider<MyMatchmakerCubit>.value(
            value: matchmaker,
            child: Scaffold(
              body: HomeShellBody(
                badges: const BadgeCounts({}),
                onOpenChat: () {},
                onOpenInbox: () {},
                tabs: const SizedBox.expand(key: _tabsKey),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _banner => find
    .ancestor(
      of: find.text(LocaleKeys.errors_offline),
      matching: find.byType(Material),
    )
    .first;

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('offline, the banner comes out from under the bar', (
    tester,
  ) async {
    await _pump(tester, offline: true);

    expect(find.text(LocaleKeys.errors_offline), findsOneWidget);
    final bar = tester.getRect(find.byType(ShellTopBar));
    final banner = tester.getRect(_banner);
    expect(bar.top, 0, reason: 'the bar stays where it was, uncovered');
    expect(banner.top, bar.bottom);
    expect(tester.getRect(find.byKey(_tabsKey)).top, banner.bottom);
  });

  testWidgets('online, the tabs start right under the bar', (tester) async {
    await _pump(tester, offline: false);

    expect(find.text(LocaleKeys.errors_offline), findsNothing);
    expect(
      tester.getRect(find.byKey(_tabsKey)).top,
      tester.getRect(find.byType(ShellTopBar)).bottom,
    );
  });
}
