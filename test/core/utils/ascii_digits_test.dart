import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/utils/ascii_digits.dart';

/// Arabic-Indic and Persian digits become ASCII; nothing else is touched.
void main() {
  group('toAsciiDigits', () {
    test('Arabic-Indic ٠–٩', () {
      expect(toAsciiDigits('٠١٢٣٤٥٦٧٨٩'), '0123456789');
    });

    test('Persian ۰–۹', () {
      expect(toAsciiDigits('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
    });

    test('mixed with ASCII digits, letters, spaces and signs', () {
      expect(toAsciiDigits('+٩٧٠ 59۱ 2a'), '+970 591 2a');
    });

    test('Arabic letters and other text stay as they are', () {
      expect(toAsciiDigits('رمز QERAN😀'), 'رمز QERAN😀');
      expect(toAsciiDigits(''), '');
    });
  });

  group('AsciiDigitsFormatter', () {
    const formatter = AsciiDigitsFormatter();

    test('converts and keeps the cursor where it was', () {
      const typed = TextEditingValue(
        text: '٥٩١',
        selection: TextSelection.collapsed(offset: 2),
      );
      final out = formatter.formatEditUpdate(TextEditingValue.empty, typed);
      expect(out.text, '591');
      expect(out.selection, typed.selection);
    });

    test('hands back the same value when there is nothing to convert', () {
      const typed = TextEditingValue(text: 'abc');
      expect(
        identical(
          formatter.formatEditUpdate(TextEditingValue.empty, typed),
          typed,
        ),
        isTrue,
      );
    });
  });
}
