import 'package:flutter/services.dart';

/// [text] with Arabic-Indic digits (٠–٩, U+0660–0669) and Extended
/// Arabic-Indic / Persian digits (۰–۹, U+06F0–06F9) as ASCII 0–9. Nothing
/// else changes.
///
/// For the inputs that are numbers to the server: a phone number, an OTP, a
/// discount code. Never for a password (it would change the credential the
/// user believes they set), a name, or prose.
String toAsciiDigits(String text) {
  final buffer = StringBuffer();
  for (final unit in text.codeUnits) {
    buffer.writeCharCode(_ascii(unit));
  }
  return buffer.toString();
}

int _ascii(int unit) {
  if (unit >= 0x0660 && unit <= 0x0669) return unit - 0x0660 + 0x30;
  if (unit >= 0x06F0 && unit <= 0x06F9) return unit - 0x06F0 + 0x30;
  return unit;
}

/// Converts digits as they're typed or pasted, so the field shows what is
/// validated and sent. One code unit for one, so the cursor and the selection
/// stay where they were. Put it before any digits-only filter, which would
/// otherwise drop «١» without a word.
class AsciiDigitsFormatter extends TextInputFormatter {
  const AsciiDigitsFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = toAsciiDigits(newValue.text);
    return text == newValue.text ? newValue : newValue.copyWith(text: text);
  }
}
