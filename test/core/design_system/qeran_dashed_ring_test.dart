import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/widgets/qeran_dashed_ring.dart';

Future<void> _pump(WidgetTester tester, Widget ring) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: Center(child: ring)),
  ),
);

Finder get _ring => find.byType(QeranDashedRing);

void main() {
  testWidgets('draws a stroke in the given colour and width', (tester) async {
    await _pump(
      tester,
      const QeranDashedRing(
        color: QeranColors.goldDeep,
        child: SizedBox.square(dimension: 40),
      ),
    );

    expect(
      tester.renderObject(_ring),
      paints..path(
        color: QeranColors.goldDeep,
        strokeWidth: 1.5,
        style: PaintingStyle.stroke,
      ),
    );
  });

  // A closed shape must not end in a clipped half-dash where the outline
  // meets itself: every dash is the same length.
  testWidgets('spreads equal dashes around the outline', (tester) async {
    await _pump(
      tester,
      const QeranDashedRing(
        color: QeranColors.goldDeep,
        child: SizedBox.square(dimension: 40),
      ),
    );

    var dashLengths = <double>[];
    expect(
      tester.renderObject(_ring),
      paints..something((method, arguments) {
        if (method != #drawPath) return false;
        dashLengths = [
          for (final dash in (arguments.first as Path).computeMetrics())
            dash.length,
        ];
        return true;
      }),
    );

    expect(dashLengths.length, greaterThan(1), reason: 'dashed, not solid');
    // Re-measuring a dash cut from a curve drifts by a few percent; a clipped
    // seam dash would be off by half.
    final mean = dashLengths.reduce((a, b) => a + b) / dashLengths.length;
    for (final length in dashLengths) {
      expect(length, moreOrLessEquals(mean, epsilon: mean * 0.1));
    }
  });

  testWidgets('also draws around a rounded rectangle', (tester) async {
    await _pump(
      tester,
      const QeranDashedRing(
        color: QeranColors.wine20,
        borderRadius: QeranRadii.cardR,
        child: SizedBox(width: 300, height: 200),
      ),
    );

    expect(
      tester.renderObject(_ring),
      paints..path(color: QeranColors.wine20, style: PaintingStyle.stroke),
    );
  });

  // Drawn inside the box like a CSS border: wrapping a 40 pt avatar must
  // leave it a 40 pt avatar, or the bar around it shifts.
  testWidgets('keeps the child size', (tester) async {
    await _pump(
      tester,
      const QeranDashedRing(
        color: QeranColors.goldDeep,
        child: SizedBox.square(dimension: 40),
      ),
    );

    expect(tester.getSize(_ring), const Size.square(40));
  });

  testWidgets('paints nothing on an empty box', (tester) async {
    await _pump(
      tester,
      const QeranDashedRing(
        color: QeranColors.goldDeep,
        child: SizedBox.shrink(),
      ),
    );

    expect(tester.renderObject(_ring), isNot(paints..path()));
  });
}
