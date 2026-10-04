import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_composer.dart';

/// A composer field that waits for a tap: Community's while the name or the
/// guidelines step comes first (D7, D17). The tap must reach the caller,
/// and nothing else may happen — no focus, no keyboard.
void main() {
  late FocusNode focus;
  late int taps;

  setUp(() {
    focus = FocusNode();
    taps = 0;
  });

  tearDown(() => focus.dispose());

  Future<void> pump(WidgetTester tester, {required bool readOnly}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QeranComposerField(
              controller: TextEditingController(),
              focusNode: focus,
              hint: 'Write a comment…',
              readOnly: readOnly,
              onTap: () => taps++,
            ),
          ),
        ),
      );

  testWidgets('waiting, a tap reaches the caller and nothing else', (
    tester,
  ) async {
    await pump(tester, readOnly: true);

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(taps, 1);
    expect(focus.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('waiting, asking for the focus does nothing', (tester) async {
    await pump(tester, readOnly: true);

    focus.requestFocus();
    await tester.pump();

    expect(focus.hasFocus, isFalse);
  });

  testWidgets('once it stops waiting, it takes the focus and the keyboard', (
    tester,
  ) async {
    await pump(tester, readOnly: true);
    await pump(tester, readOnly: false);

    focus.requestFocus();
    await tester.pump();

    expect(focus.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('not waiting, a tap still reaches the caller', (tester) async {
    await pump(tester, readOnly: false);

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(taps, 1);
    expect(focus.hasFocus, isTrue);
  });
}
