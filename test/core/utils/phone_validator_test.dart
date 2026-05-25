import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/utils/phone_validator.dart';

void main() {
  group('PhoneValidator', () {
    test('returns error when null or empty', () {
      expect(PhoneValidator.validate(null), 'رقم الهاتف مطلوب');
      expect(PhoneValidator.validate(''), 'رقم الهاتف مطلوب');
      expect(PhoneValidator.validate('   '), 'رقم الهاتف مطلوب');
    });

    test('returns error when contains non-digits', () {
      expect(
        PhoneValidator.validate('591234abc'),
        'رقم الهاتف يجب أن يحتوي على أرقام فقط',
      );
      expect(
        PhoneValidator.validate('591-234-567'),
        'رقم الهاتف يجب أن يحتوي على أرقام فقط',
      );
    });

    test('returns error when too short', () {
      expect(PhoneValidator.validate('123456'), 'رقم الهاتف قصير جداً');
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
