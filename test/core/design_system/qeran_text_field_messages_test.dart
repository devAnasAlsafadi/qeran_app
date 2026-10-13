import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_helper_line.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';

import '../shipped_fonts_rig.dart';

/// Run 7 (Anas's hand check): a field's messages are never cut. The
/// forgot-password phone error read «رقم الهاتف يجب أن يحتوي على أرق…».
/// An error, a hint and a help line each wrap onto as many lines as they
/// need, whatever puts them there.
const _long = 'رقم الهاتف يجب أن يحتوي على أرقام فقط، دون مسافات أو رموز';

/// The phone field's room at 360, beside the country code.
const _phoneWidth = 186.0;

Future<void> _pump(WidgetTester tester, Widget field) =>
    pumpOnPhone(tester, 'ar', SizedBox(width: _phoneWidth, child: field));

/// Whole: laid out without hitting a line limit, on more than one line.
void _expectWrappedWhole(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  expect(paragraph.didExceedMaxLines, isFalse, reason: 'cut');
  expect(
    paragraph.size.height,
    greaterThan(paragraph.getMaxIntrinsicHeight(_phoneWidth) / 2),
  );
}

void main() {
  setUpAll(loadShippedFonts);

  final controller = TextEditingController();
  tearDownAll(controller.dispose);

  testWidgets('an error wraps whole', (tester) async {
    await _pump(
      tester,
      QeranTextField(controller: controller, errorText: _long),
    );
    _expectWrappedWhole(tester, _long);
  });

  testWidgets('a validator message wraps whole', (tester) async {
    final form = GlobalKey<FormState>();
    await _pump(
      tester,
      Form(
        key: form,
        child: QeranTextField(controller: controller, validator: (_) => _long),
      ),
    );
    form.currentState!.validate();
    await tester.pump();
    _expectWrappedWhole(tester, _long);
  });

  testWidgets('a hint wraps whole', (tester) async {
    await _pump(tester, QeranTextField(controller: controller, hint: _long));
    _expectWrappedWhole(tester, _long);
  });

  testWidgets('a help line, and its error, wrap whole', (tester) async {
    await _pump(
      tester,
      QeranTextField(
        controller: controller,
        helper: const QeranHelperLine(icon: Icons.info_outline, text: _long),
      ),
    );
    _expectWrappedWhole(tester, _long);
  });
}
