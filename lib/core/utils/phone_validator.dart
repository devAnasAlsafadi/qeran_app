import 'package:qeran/generated/locale_keys.g.dart';

class PhoneValidator {
  static String? validate(String? localNumber) {
    if (localNumber == null || localNumber.trim().isEmpty) {
      return LocaleKeys.validators_phone_required;
    }
    final cleaned = localNumber.trim().replaceAll(RegExp(r'\s+'), '');
    if (RegExp(r'[^0-9]').hasMatch(cleaned)) {
      return LocaleKeys.validators_phone_digits_only;
    }
    if (cleaned.length < 7) {
      return LocaleKeys.validators_phone_too_short;
    }
    return null;
  }
}
