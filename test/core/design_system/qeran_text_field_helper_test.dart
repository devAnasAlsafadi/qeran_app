import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_helper_line.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';

/// The field's help line (Community's name step, Profile › Name): one line
/// under the field that says what the field is for, and — in the same
/// shape — what's wrong with it.

const _help = 'Shown with your comments';

Future<GlobalKey<FormState>> _pump(
  WidgetTester tester, {
  bool helper = true,
  String? errorText,
  String? Function(String?)? validator,
}) async {
  final form = GlobalKey<FormState>();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Form(
          key: form,
          child: QeranTextField(
            controller: TextEditingController(),
            maxLength: 50,
            errorText: errorText,
            validator: validator,
            helper: helper
                ? const QeranHelperLine(icon: Icons.forum_outlined, text: _help)
                : null,
          ),
        ),
      ),
    ),
  );
  return form;
}

Color? _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  testWidgets('shows its icon and text, beside the counter', (tester) async {
    await _pump(tester);

    expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
    expect(find.text(_help), findsOneWidget);
    expect(find.text('0/50'), findsOneWidget);
    expect(_colorOf(tester, _help), QeranColors.inkMuted);
  });

  testWidgets("a validator's message takes the line's place", (tester) async {
    final form = await _pump(tester, validator: (_) => 'Choose another');

    form.currentState!.validate();
    await tester.pumpAndSettle();

    expect(find.text('Choose another'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(_colorOf(tester, 'Choose another'), QeranColors.danger);
    expect(find.text(_help), findsNothing);
    // The counter stays where it was.
    expect(find.text('0/50'), findsOneWidget);
  });

  testWidgets('errorText takes the same shape', (tester) async {
    await _pump(tester, errorText: 'Not allowed');
    await tester.pumpAndSettle();

    expect(find.text('Not allowed'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.text(_help), findsNothing);
  });

  testWidgets('an error turns the edge danger, as without a line', (
    tester,
  ) async {
    await _pump(tester, errorText: 'Not allowed');

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration!.error, isNotNull);
    expect(field.decoration!.errorText, isNull);
  });

  testWidgets('without a help line, errors stay bare text', (tester) async {
    final form = await _pump(
      tester,
      helper: false,
      validator: (_) => 'Required',
    );

    form.currentState!.validate();
    await tester.pumpAndSettle();

    expect(find.text('Required'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
  });
}
