import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: Center(child: child)),
  ),
);

BoxDecoration _decorationOf(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find.descendant(
                of: find.byType(QeranChip),
                matching: find.byType(DecoratedBox),
              ),
            )
            .decoration
        as BoxDecoration;

void main() {
  group('highlight', () {
    testWidgets('is solid gold with a wine label', (tester) async {
      await _pump(
        tester,
        const QeranChip(
          label: 'New message',
          variant: QeranChipVariant.highlight,
        ),
      );

      expect(_decorationOf(tester).color, QeranColors.gold);
      expect(
        tester.widget<Text>(find.text('New message')).style?.color,
        QeranColors.wine,
      );
    });

    // Identity rule: news waiting for the member is an invitation, not a
    // fault. Red is reserved for danger, and this must never drift to it.
    testWidgets('never borrows danger', (tester) async {
      await _pump(
        tester,
        const QeranChip(
          label: 'New message',
          variant: QeranChipVariant.highlight,
        ),
      );

      expect(_decorationOf(tester).color, isNot(QeranColors.danger));
    });

    // A solid fill needs no rim; a border would read as a second shape.
    testWidgets('has no border', (tester) async {
      await _pump(
        tester,
        const QeranChip(
          label: 'New message',
          variant: QeranChipVariant.highlight,
        ),
      );

      expect(_decorationOf(tester).border, isNull);
    });
  });
}
