import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_nav.dart';
import 'package:qeran/features/badges/domain/entities/badge_counts.dart';
import 'package:qeran/features/badges/domain/usecases/get_badges_usecase.dart';
import 'package:qeran/features/badges/domain/usecases/mark_tab_seen_usecase.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/features/home/presentation/widgets/home_nav_items.dart';
import 'package:qeran/features/matchmaker/home/presentation/widgets/matchmaker_bottom_nav.dart';

/// Pumps either app's bottom nav on a 360-wide phone, and finds its parts.
/// Labels render as their keys (a stub loader), which keeps them unique.

class _FakeGet extends Fake implements GetBadgesUseCase {}

class _FakeMark extends Fake implements MarkTabSeenUseCase {}

class NavBadgesCubit extends BadgesCubit {
  NavBadgesCubit() : super(getBadges: _FakeGet(), markTabSeen: _FakeMark());
  @override
  Future<void> refresh() async {}
}

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

/// Either app's nav, at [index], on a 360-wide phone; a tap moves it.
Widget memberNav(BuildContext context, int index, ValueChanged<int> onTap) =>
    QeranBottomNav(
      items: buildHomeNavItems(context, const BadgeCounts.empty()),
      currentIndex: index,
      onTap: onTap,
    );

Widget herNav(BuildContext context, int index, ValueChanged<int> onTap) =>
    MatchmakerBottomNav(currentIndex: index, onTap: onTap);

typedef NavBuilder = Widget Function(BuildContext, int, ValueChanged<int>);

Future<void> pumpNav(
  WidgetTester tester,
  String lang,
  NavBuilder nav,
  int at, {
  Size size = const Size(360, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  var index = at;
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: [Locale(lang)],
      startLocale: Locale(lang),
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              bottomNavigationBar: nav(
                context,
                index,
                (i) => setState(() => index = i),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<QeranNavItem> navItems(WidgetTester tester) =>
    tester.widget<QeranBottomNav>(find.byType(QeranBottomNav)).items;

Rect navDisc(WidgetTester tester) =>
    tester.getRect(find.byKey(QeranBottomNav.discKey));

/// [item]'s picture in one state: its Material icon, or its SVG.
Finder glyphOf(QeranNavItem item, {required bool filled}) {
  final icon = filled ? item.filledIcon : item.outlineIcon;
  if (icon != null) return find.byIcon(icon);
  final asset = filled ? item.filledSvg : item.outlineSvg;
  return find.byWidgetPredicate(
    (w) =>
        w is SvgPicture && (w.bytesLoader as SvgAssetLoader).assetName == asset,
  );
}

bool tintedWith(WidgetTester tester, Finder glyph, Color color) =>
    switch (tester.widget(glyph)) {
      final Icon icon => icon.color == color,
      final SvgPicture svg =>
        svg.colorFilter == ColorFilter.mode(color, BlendMode.srcIn),
      _ => false,
    };

double opacityOf(WidgetTester tester, Finder glyph) => tester
    .widget<FadeTransition>(
      find.ancestor(of: glyph, matching: find.byType(FadeTransition)).first,
    )
    .opacity
    .value;
