import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_nav.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'qeran_bottom_nav_rig.dart';

/// Run 8 (the client): the selected tab stays in its own place inside the
/// bar — a gold disc behind its filled wine icon, its label wine and bold —
/// so nothing rises above the island or is cut by its edges. Both apps.

/// The disc lies wholly inside the island, centred on the selected tab: over
/// its label, and level with every other tab's icon (no lift).
void _expectInPlace(WidgetTester tester, int selected) {
  final bar = tester.getRect(find.byKey(QeranBottomNav.barKey));
  final disc = navDisc(tester);
  expect(bar.contains(disc.topLeft) && bar.contains(disc.bottomRight), isTrue);
  final items = navItems(tester);
  final label = tester.getRect(find.text(items[selected].label));
  expect(disc.center.dx, moreOrLessEquals(label.center.dx, epsilon: 0.5));
  // The label under it, whole: not overlapped, squeezed or pushed out.
  expect(label.top, greaterThanOrEqualTo(disc.bottom));
  expect(label.bottom, lessThanOrEqualTo(bar.bottom));
  final text = tester.widget<Text>(find.text(items[selected].label));
  final whole = TextPainter(
    text: TextSpan(text: text.data, style: text.style),
    textDirection: TextDirection.ltr,
  )..layout();
  addTearDown(whole.dispose);
  expect(label.height, moreOrLessEquals(whole.height, epsilon: 0.5));
  for (var i = 0; i < items.length; i++) {
    if (i == selected) continue;
    final icon = tester.getCenter(glyphOf(items[i], filled: false));
    expect(disc.center.dy, moreOrLessEquals(icon.dy, epsilon: 0.5));
  }
}

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
      testWidgets('$app nav: every selected tab sits in place [$lang]', (
        tester,
      ) async {
        for (var i = 0; i < count; i++) {
          await pumpNav(tester, lang, nav, i);
          _expectInPlace(tester, i);
        }
      });

      testWidgets('$app nav: the selected tab is coloured, the rest muted '
          '[$lang]', (tester) async {
        for (var selected = 0; selected < count; selected++) {
          await pumpNav(tester, lang, nav, selected);
          final items = navItems(tester);
          for (var i = 0; i < count; i++) {
            final on = i == selected;
            final label = tester.widget<Text>(find.text(items[i].label));
            final style = label.style!;
            expect(style.color, on ? QeranColors.wine : QeranColors.inkMuted);
            expect(style.fontWeight, on ? FontWeight.w700 : FontWeight.w500);
            final filled = glyphOf(items[i], filled: true);
            final outline = glyphOf(items[i], filled: false);
            expect(opacityOf(tester, filled), on ? 1 : 0);
            expect(opacityOf(tester, outline), on ? 0 : 1);
            expect(tintedWith(tester, filled, QeranColors.wine), isTrue);
            expect(tintedWith(tester, outline, QeranColors.inkMuted), isTrue);
          }
          // An SVG tab draws at the icons' own size.
          final sizes = {
            for (final item in items) ...[
              tester.getSize(glyphOf(item, filled: true)),
              tester.getSize(glyphOf(item, filled: false)),
            ],
          };
          expect(sizes, hasLength(1));
        }
      });
    }

    testWidgets('$app nav: a tap moves the disc, never out of the bar', (
      tester,
    ) async {
      await pumpNav(tester, 'ar', nav, 0);
      final bar = tester.getRect(find.byKey(QeranBottomNav.barKey));
      await tester.tap(find.text(navItems(tester)[count - 1].label));
      for (var frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 80));
        final disc = navDisc(tester);
        expect(disc.top, greaterThanOrEqualTo(bar.top));
        expect(disc.bottom, lessThanOrEqualTo(bar.bottom));
      }
      await tester.pumpAndSettle();
      _expectInPlace(tester, count - 1);
    });
  }
}
