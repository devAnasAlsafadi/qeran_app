import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/utils/phone_formatter.dart';

void main() {
  group('PhoneFormatter', () {
    test('formats local number and country code correctly', () {
      expect(PhoneFormatter.toApiFormat('+970', '591234567'), '970591234567');
    });

    test('strips leading zero from local number', () {
      expect(PhoneFormatter.toApiFormat('+972', '0591234567'), '972591234567');
    });

    test('strips spaces from local number', () {
      expect(PhoneFormatter.toApiFormat('+970', ' 59 123 4567 '), '970591234567');
    });

    test('works without plus sign in country code', () {
      expect(PhoneFormatter.toApiFormat('970', '591234567'), '970591234567');
    });
  });
}
