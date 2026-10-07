import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_progress_bar.dart';

Future<Rect> _fill(
  WidgetTester tester,
  double value, {
  TextDirection direction = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: direction,
      child: Center(
        child: SizedBox(width: 200, child: QeranProgressBar(value: value)),
      ),
    ),
  );
  return tester.getRect(
    find.byWidgetPredicate(
      (w) => w is ColoredBox && w.color == QeranColors.goldDeep,
    ),
  );
}

void main() {
  testWidgets('4 high; the gold-deep fill covers the value, from the left '
      'in English', (tester) async {
    final fill = await _fill(tester, 0.62);
    final track = tester.getRect(find.byType(QeranProgressBar));

    expect(track.height, QeranProgressBar.height);
    expect(fill.width, closeTo(124, 0.01));
    expect(fill.left, track.left);
  });

  testWidgets('from the right in Arabic', (tester) async {
    final fill = await _fill(tester, 0.25, direction: TextDirection.rtl);
    final track = tester.getRect(find.byType(QeranProgressBar));

    expect(fill.width, closeTo(50, 0.01));
    expect(fill.right, track.right);
  });

  testWidgets('clamped: below 0 is empty, above 1 is full', (tester) async {
    expect((await _fill(tester, -0.3)).width, 0);
    expect((await _fill(tester, 1.4)).width, 200);
  });
}
