import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_nav.dart';
import 'package:qeran/features/badges/domain/entities/badge_counts.dart';
import 'package:qeran/features/badges/domain/entities/badge_tab_keys.dart';
import 'package:qeran/features/badges/domain/entities/nav_badge_tabs.dart';
import 'package:qeran/features/home/presentation/home_shell_navigator.dart';
import 'package:qeran/features/home/presentation/widgets/home_nav_items.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Strings render as their keys, so the labels name the key they read.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

/// Every count non-zero, so a badge that is wired at all shows up.
const _allUnread = BadgeCounts({
  BadgeTabKeys.likes: 3,
  BadgeTabKeys.chat: 4,
  BadgeTabKeys.account: 5,
  BadgeTabKeys.explore: 6,
});

Future<List<QeranNavItem>> _items(WidgetTester tester) async {
  late List<QeranNavItem> items;
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
          home: Builder(
            builder: (context) {
              items = buildHomeNavItems(context, _allUnread);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return items;
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('four tabs: Community, Suggestions, Interests, Profile', (
    tester,
  ) async {
    final items = await _items(tester);

    expect(items.map((i) => i.label), [
      LocaleKeys.home_nav_community,
      LocaleKeys.home_nav_marriage,
      LocaleKeys.home_nav_likes,
      LocaleKeys.home_nav_profile,
    ]);
  });

  // The items, the navigator's indices and the badge map are three lists of
  // the same tabs; they must agree on where each one sits.
  testWidgets('the order matches the navigator\'s tab indices', (tester) async {
    final items = await _items(tester);

    expect(
      items[HomeShellNavigator.communityTab].label,
      LocaleKeys.home_nav_community,
    );
    expect(
      items[HomeShellNavigator.discoveryTab].label,
      LocaleKeys.home_nav_marriage,
    );
    expect(items[HomeShellNavigator.likesTab].label, LocaleKeys.home_nav_likes);
    expect(
      items[HomeShellNavigator.profileTab].label,
      LocaleKeys.home_nav_profile,
    );
  });

  testWidgets('a dot only where the badge map clears one', (tester) async {
    final items = await _items(tester);

    final dotted = [
      for (var i = 0; i < items.length; i++)
        if ((items[i].badgeCount ?? 0) > 0) i,
    ];
    expect(dotted, unorderedEquals(NavBadgeTabs.user.keys));
  });

  // Chat unread belongs to the top bar now, not to any tab.
  testWidgets('no tab carries the chat count', (tester) async {
    final items = await _items(tester);

    expect(items.map((i) => i.badgeCount), isNot(contains(4)));
  });
}
