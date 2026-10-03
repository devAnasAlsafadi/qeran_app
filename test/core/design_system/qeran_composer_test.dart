import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_composer.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: Center(child: SizedBox(width: 320, child: child)),
    ),
  ),
);

InputDecoration _decoration(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).decoration!;

Color _edge(InputBorder? border) =>
    (border! as OutlineInputBorder).borderSide.color;

void main() {
  group('the field', () {
    testWidgets('a quiet edge, wine while focused', (tester) async {
      await _pump(
        tester,
        QeranComposerField(controller: TextEditingController(), hint: 'Write'),
      );

      expect(_edge(_decoration(tester).enabledBorder), QeranColors.wine08);
      expect(_edge(_decoration(tester).focusedBorder), QeranColors.wine);
    });

    testWidgets('in error: danger, focused or not', (tester) async {
      await _pump(
        tester,
        QeranComposerField(
          controller: TextEditingController(),
          hint: 'Write',
          error: true,
        ),
      );

      expect(_edge(_decoration(tester).enabledBorder), QeranColors.danger);
      expect(_edge(_decoration(tester).focusedBorder), QeranColors.danger);
    });

    testWidgets('a cap stops the text; without one it runs on', (tester) async {
      final capped = TextEditingController();
      await _pump(
        tester,
        QeranComposerField(controller: capped, hint: 'Write', maxLength: 5),
      );
      await tester.enterText(find.byType(TextField), 'abcdefgh');
      expect(capped.text, 'abcde');

      final open = TextEditingController();
      await _pump(tester, QeranComposerField(controller: open, hint: 'Write'));
      await tester.enterText(find.byType(TextField), 'abcdefgh');
      expect(open.text, 'abcdefgh');
    });

    testWidgets('follows the direction and script it is given', (tester) async {
      await _pump(
        tester,
        QeranComposerField(
          controller: TextEditingController(),
          hint: 'Write',
          textDirection: TextDirection.rtl,
          fontFamily: 'NotoKufiArabic',
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textDirection, TextDirection.rtl);
      expect(field.style?.fontFamily, 'NotoKufiArabic');
    });
  });

  group('the send button', () {
    Color fill(WidgetTester tester) => tester
        .widget<Material>(
          find.descendant(
            of: find.byType(QeranSendButton),
            matching: find.byType(Material),
          ),
        )
        .color!;

    testWidgets('enabled: gold, and a tap sends', (tester) async {
      var sends = 0;
      await _pump(
        tester,
        QeranSendButton(enabled: true, onPressed: () => sends++),
      );

      expect(fill(tester), QeranColors.gold);
      await tester.tap(find.byType(QeranSendButton));
      expect(sends, 1);
    });

    testWidgets('disabled: faded gold, and a tap does nothing', (tester) async {
      var sends = 0;
      await _pump(
        tester,
        QeranSendButton(enabled: false, onPressed: () => sends++),
      );

      expect(fill(tester), QeranColors.gold40);
      await tester.tap(find.byType(QeranSendButton));
      expect(sends, 0);
    });

    testWidgets('sending: a loader, and a tap does nothing', (tester) async {
      var sends = 0;
      await _pump(
        tester,
        QeranSendButton(enabled: true, sending: true, onPressed: () => sends++),
      );

      expect(find.byType(QeranLoader), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsNothing);
      await tester.tap(find.byType(QeranSendButton));
      expect(sends, 0);
    });

    testWidgets('a 44 pt disc', (tester) async {
      await _pump(
        tester,
        Center(child: QeranSendButton(enabled: true, onPressed: () {})),
      );

      expect(
        tester.getSize(find.byType(QeranSendButton)),
        const Size.square(44),
      );
    });
  });
}
