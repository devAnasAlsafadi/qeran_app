import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_page_indicator.dart';

Future<void> _pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Center(child: child)));

/// Each dot's size (without its 3 dp margins) and colour, in order.
List<(Size, Color?)> _dots(WidgetTester tester) => [
  for (final dot in tester.widgetList<AnimatedContainer>(
    find.byType(AnimatedContainer),
  ))
    (dot.constraints!.biggest, (dot.decoration as BoxDecoration?)?.color),
];

void main() {
  testWidgets('photo tone, as before: gold 8 dp active, cream 6 dp', (
    tester,
  ) async {
    await _pump(tester, const QeranPageDots(count: 3, current: 1));

    expect(_dots(tester), [
      (const Size(6, 6), QeranColors.creamSurface),
      (const Size(8, 8), QeranColors.gold),
      (const Size(6, 6), QeranColors.creamSurface),
    ]);
  });

  testWidgets('paper tone: a gold-deep 18 × 6 pill active, wine-20 6 dp', (
    tester,
  ) async {
    await _pump(
      tester,
      const QeranPageDots(count: 3, current: 0, tone: QeranPageDotsTone.paper),
    );

    expect(_dots(tester), [
      (const Size(18, 6), QeranColors.goldDeep),
      (const Size(6, 6), QeranColors.wine20),
      (const Size(6, 6), QeranColors.wine20),
    ]);
  });

  testWidgets('wine tone (the media viewer): a gold 18 × 6 pill, gold-40 '
      '6 dp', (tester) async {
    await _pump(
      tester,
      const QeranPageDots(count: 3, current: 2, tone: QeranPageDotsTone.wine),
    );

    expect(_dots(tester), [
      (const Size(6, 6), QeranColors.gold40),
      (const Size(6, 6), QeranColors.gold40),
      (const Size(18, 6), QeranColors.gold),
    ]);
  });

  testWidgets('the counter and the overlay pill read left to right', (
    tester,
  ) async {
    await _pump(
      tester,
      const Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QeranPageCounter(index: 2, total: 5),
            QeranOverlayPill('0:52'),
          ],
        ),
      ),
    );

    for (final text in ['2 / 5', '0:52']) {
      expect(
        tester.widget<Text>(find.text(text)).textDirection,
        TextDirection.ltr,
      );
    }
  });
}
