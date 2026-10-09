import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_strokes.dart';
import 'package:qeran/core/design_system/widgets/qeran_card.dart';

void main() {
  Future<BoxDecoration> decorationOf(
    WidgetTester tester,
    QeranCard card,
  ) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: card)));
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(QeranCard),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    return box.decoration as BoxDecoration;
  }

  testWidgets('a standard card has no edge by default', (tester) async {
    final decoration = await decorationOf(
      tester,
      const QeranCard(child: SizedBox()),
    );

    expect(decoration.border, isNull);
  });

  testWidgets('a border colour draws a hairline in that colour', (
    tester,
  ) async {
    final decoration = await decorationOf(
      tester,
      const QeranCard(borderColor: QeranColors.gold40, child: SizedBox()),
    );

    final border = decoration.border! as Border;
    expect(border.top.color, QeranColors.gold40);
    expect(border.top.width, QeranStrokes.hairline);
  });

  testWidgets('a flat card keeps its wine-08 edge', (tester) async {
    final decoration = await decorationOf(
      tester,
      const QeranCard.flat(child: SizedBox()),
    );

    expect((decoration.border! as Border).top.color, QeranColors.wine08);
  });

  testWidgets('a border colour replaces the flat card\'s edge', (tester) async {
    final decoration = await decorationOf(
      tester,
      const QeranCard.flat(borderColor: QeranColors.gold40, child: SizedBox()),
    );

    expect((decoration.border! as Border).top.color, QeranColors.gold40);
  });
}
