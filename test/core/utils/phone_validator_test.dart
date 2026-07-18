import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/utils/phone_validator.dart';
import 'package:qeran/generated/locale_keys.g.dart';

void main() {
  group('PhoneValidator', () {
    // The validator returns localization KEYS (localized at the call site),
    // never hardcoded copy.
    test('returns error when null or empty', () {
      expect(PhoneValidator.validate(null), LocaleKeys.validators_phone_required);
      expect(PhoneValidator.validate(''), LocaleKeys.validators_phone_required);
      expect(
          PhoneValidator.validate('   '), LocaleKeys.validators_phone_required);
    });

    test('returns error when contains non-digits', () {
      expect(
        PhoneValidator.validate('591234abc'),
        LocaleKeys.validators_phone_digits_only,
      );
      expect(
        PhoneValidator.validate('591-234-567'),
        LocaleKeys.validators_phone_digits_only,
      );
    });

    test('returns error when too short', () {
      expect(
          PhoneValidator.validate('123456'), LocaleKeys.validators_phone_too_short);
    });

    test('returns null when valid', () {
      expect(PhoneValidator.validate('591234567'), null);
      expect(
        PhoneValidator.validate('591 234 567'),
        null,
      ); // spaces are ignored
    });
  });
}
