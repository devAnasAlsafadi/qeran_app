import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/utils/log_masker.dart';

void main() {
  group('LogMasker.phone', () {
    test('null → ***', () {
      expect(LogMasker.phone(null), '***');
    });

    test('empty → ***', () {
      expect(LogMasker.phone(''), '***');
    });

    test('shorter than 7 digits → ***', () {
      expect(LogMasker.phone('123'), '***');
      expect(LogMasker.phone('123456'), '***');
    });

    test('12-digit number is masked first 3 + last 4', () {
      expect(LogMasker.phone('970591234567'), '970*****4567');
    });

    test('leading + is preserved and only the digits are masked', () {
      expect(LogMasker.phone('+970591234567'), '+970*****4567');
    });

    test('+ followed by too few digits → ***', () {
      expect(LogMasker.phone('+12'), '***');
    });

    test('exactly 7 digits returns the input unchanged (no middle to mask)', () {
      // Boundary case: prefix=3, suffix=4 leaves zero middle chars.
      expect(LogMasker.phone('1234567'), '1234567');
    });

    test('8 digits → one star in the middle', () {
      expect(LogMasker.phone('12345678'), '123*5678');
    });

    test('+ with exactly 7 digits keeps the + and produces no stars', () {
      expect(LogMasker.phone('+1234567'), '+1234567');
    });
  });

  group('LogMasker.otp', () {
    test('null → otp_len=0', () {
      expect(LogMasker.otp(null), 'otp_len=0');
    });

    test('empty → otp_len=0', () {
      expect(LogMasker.otp(''), 'otp_len=0');
    });

    test('reports length without leaking the value', () {
      expect(LogMasker.otp('1234'), 'otp_len=4');
      expect(LogMasker.otp('123456'), 'otp_len=6');
    });
  });
}
