import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_notice.dart';

const _long =
    'Your profile is under review. You can read now; liking and '
    'commenting open once it’s approved.';

void main() {
  testWidgets('gold ground, gold-deep icon, strong ink; long text wraps', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 240,
            child: QeranNotice(icon: Icons.hourglass_top_rounded, text: _long),
          ),
        ),
      ),
    );

    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(QeranNotice),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect((box.decoration as BoxDecoration).color, QeranColors.gold12);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.hourglass_top_rounded)).color,
      QeranColors.goldDeep,
    );
    expect(
      tester.widget<Text>(find.text(_long)).style?.color,
      QeranColors.inkStrong,
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(QeranNotice)).height, greaterThan(60));
  });
}
