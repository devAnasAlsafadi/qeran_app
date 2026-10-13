import 'package:qeran/core/utils/ascii_digits.dart';

class PhoneFormatter {
  /// Combines country code and local number into API format: 972XXXXXXXXX
  /// - Strips "+" from country code
  /// - Strips leading "0" from local number
  /// - Trims whitespace
  /// - Arabic-Indic and Persian digits as ASCII (a leading «٠» included)
  static String toApiFormat(String countryCode, String localNumber) {
    final code = countryCode.replaceAll('+', '').trim();
    var local = toAsciiDigits(
      localNumber.trim(),
    ).replaceAll(RegExp(r'\s+'), '');
    if (local.startsWith('0')) local = local.substring(1);
    return '$code$local';
  }
}
