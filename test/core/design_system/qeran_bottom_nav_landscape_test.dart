import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_nav.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'qeran_bottom_nav_rig.dart';

/// Run 8 (Anas): landscape marks the selected tab as portrait does — a gold
/// disc inside the bar behind its filled wine icon, its label wine and bold.
/// Both apps, every tab, on a phone turned sideways.

const _sideways = Size(800, 360);

/// [glyph]'s disc: the nearest box holding it.
AnimatedContainer _discOf(WidgetTester tester, Finder glyph) => tester.widget(
  find.ancestor(of: glyph, matching: find.byType(AnimatedContainer)).first,
);

Color? _discColour(WidgetTester tester, Finder glyph) =>
    (_discOf(tester, glyph).decoration! as BoxDecoration).color;

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() async {
    await sl.reset();
    sl.registerLazySingleton<BadgesCubit>(NavBadgesCubit.new);
  });

  tearDown(() async => sl.reset());

  for (final (app, nav, count) in [
    ('member', memberNav, 4),
    ('her', herNav, 5),
  ]) {
    for (final lang in const ['ar', 'en']) {
      testWidgets('$app nav, landscape: the selected tab wears the disc, '
          'inside the bar [$lang]', (tester) async {
        for (var selected = 0; selected < count; selected++) {
          await pumpNav(tester, lang, nav, selected, size: _sideways);
          final items = navItems(tester);
          final bar = tester.getRect(find.byKey(QeranBottomNav.barKey));
          for (var i = 0; i < count; i++) {
            final on = i == selected;
            final glyph = glyphOf(items[i], filled: on);
            final disc = tester.getRect(
              find
                  .ancestor(of: glyph, matching: find.byType(AnimatedContainer))
                  .first,
            );
            expect(disc.size, const Size.square(QeranBottomNav.discDiameter));
            expect(bar.contains(disc.topLeft), isTrue);
            expect(bar.contains(disc.bottomRight), isTrue);
            expect(disc.center, tester.getCenter(glyph));
            expect(_discColour(tester, glyph)!.a, on ? 1 : 0);
            final tint = on ? QeranColors.wine : QeranColors.inkMuted;
            expect(tintedWith(tester, glyph, tint), isTrue);
            final style = tester.widget<Text>(find.text(items[i].label)).style!;
            expect(style.color, tint);
            expect(style.fontWeight, on ? FontWeight.w700 : FontWeight.w500);
          }
          expect(
            _discColour(tester, glyphOf(items[selected], filled: true)),
            QeranColors.gold,
          );
        }
      });
    }
  }
}
