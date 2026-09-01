import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';

/// The app-wide input. Twenty-three call sites render it, so its line
/// behaviour is pinned here rather than left to whichever screen happens to
/// notice a regression first.

Future<TextField> _pump(
  WidgetTester tester, {
  int maxLines = 1,
  int? minLines,
  bool obscureText = false,
  TextInputAction? textInputAction,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: QeranTextField(
          controller: TextEditingController(),
          maxLines: maxLines,
          minLines: minLines,
          obscureText: obscureText,
          textInputAction: textInputAction,
        ),
      ),
    ),
  );
  return tester.widget<TextField>(find.byType(TextField));
}

BorderRadius _radiusOf(TextField field) =>
    (field.decoration!.enabledBorder! as OutlineInputBorder).borderRadius;

void main() {
  group('how tall the field is', () {
    testWidgets('is single-line unless a caller says otherwise', (tester) async {
      final field = await _pump(tester);

      expect(field.maxLines, 1);
    });

    testWidgets('forwards the ceiling a caller asks for', (tester) async {
      final field = await _pump(tester, maxLines: 6);

      expect(field.maxLines, 6);
    });

    testWidgets('never gives an obscured field a second line', (tester) async {
      // A password box that grew would leak the shape of the secret.
      final field = await _pump(tester, obscureText: true, maxLines: 6);

      expect(field.maxLines, 1);
    });

    testWidgets('asks for no resting height by default', (tester) async {
      // Built WITHOUT the helper on purpose: the helper forwards `minLines:
      // null` explicitly, which overrides the constructor default and would
      // let a default of 1 slip through unnoticed. The twenty-three call
      // sites that name no resting height go through THIS path.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QeranTextField(
              controller: TextEditingController(),
              maxLines: 6,
            ),
          ),
        ),
      );

      // A multiline field opens at ONE line today and grows with typing.
      expect(tester.widget<TextField>(find.byType(TextField)).minLines, isNull);
    });
  });

  group('a resting height', () {
    testWidgets('reaches the field a caller sets it on', (tester) async {
      final field = await _pump(tester, minLines: 3, maxLines: 12);

      // Both halves matter: the box opens at three lines AND still stops
      // growing at twelve, scrolling inside itself past that.
      expect(field.minLines, 3);
      expect(field.maxLines, 12);
    });

    testWidgets('may sit exactly on the ceiling', (tester) async {
      // A fixed-height box, not a growing one. Allowed, so the assert is a
      // floor-above-ceiling guard and not an off-by-one.
      final field = await _pump(tester, minLines: 4, maxLines: 4);

      expect(field.minLines, 4);
    });

    testWidgets('is refused above the ceiling', (tester) async {
      // Left to the framework this surfaces deep inside a render object; the
      // constructor assert names it at the call site instead.
      expect(
        () => QeranTextField(
          controller: TextEditingController(),
          minLines: 3,
        ),
        throwsAssertionError,
      );
    });

    testWidgets('is dropped for obscured input rather than crashing', (
      tester,
    ) async {
      // The ceiling is forced to 1 for a password box. A resting height of 3
      // would then be taller than the ceiling and trip the framework's own
      // assert, so it goes with it.
      final field = await _pump(
        tester,
        obscureText: true,
        minLines: 3,
        maxLines: 6,
      );

      expect(field.minLines, isNull);
      expect(field.maxLines, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('the shape that follows from it', () {
    testWidgets('a single-line field is a pill', (tester) async {
      final field = await _pump(tester);

      expect(_radiusOf(field), QeranRadii.pill);
    });

    testWidgets('a text area softens to the control radius', (tester) async {
      // A stadium looks wrong on a tall box.
      final field = await _pump(tester, maxLines: 6);

      expect(_radiusOf(field), QeranRadii.controlR);
    });

    testWidgets('an obscured field keeps its pill', (tester) async {
      final field = await _pump(tester, obscureText: true, maxLines: 6);

      expect(_radiusOf(field), QeranRadii.pill);
    });
  });

  group('the keyboard action that follows from it', () {
    testWidgets('a single-line field gets a done key', (tester) async {
      final field = await _pump(tester);

      expect(field.textInputAction, TextInputAction.done);
    });

    testWidgets('a text area is left alone, so newline survives', (
      tester,
    ) async {
      // Forcing `done` here would replace the return key and make the field
      // impossible to break lines in.
      final field = await _pump(tester, maxLines: 6);

      expect(field.textInputAction, isNull);
    });

    testWidgets('a caller-set action wins over the default', (tester) async {
      final field = await _pump(tester, textInputAction: TextInputAction.next);

      expect(field.textInputAction, TextInputAction.next);
    });
  });
}
