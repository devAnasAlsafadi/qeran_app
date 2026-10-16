import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/utils/log_masker.dart';

/// Debug logs carry no token and no contact detail (cleanup audit `19`,
/// run 11): every AppLogger line, and the error passed with it, goes through
/// [LogMasker.redact].
void main() {
  const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.c2lnbmF0dXJl';

  group('LogMasker.redact', () {
    test('tokens, emails and phone numbers go', () {
      expect(LogMasker.redact('Bearer $jwt'), 'Bearer <redacted-jwt>');
      expect(
        LogMasker.redact('user dima.s+1@mail.example.com failed'),
        'user <redacted-email> failed',
      );
      expect(
        LogMasker.redact('GET /check?email=a%40b.co&x=1'),
        'GET /check?email=<redacted-email>&x=1',
      );
      expect(
        LogMasker.redact('phone=+970591234567 or 0591234567'),
        'phone=<redacted-number> or <redacted-number>',
      );
    });

    test('ids, pages, dates, counts and masked values stay', () {
      const plain =
          'conv=42 page=2/17 at 2026-10-16 11:02:03 otp_len=6 970*****4567';
      expect(LogMasker.redact(plain), plain);
    });
  });

  group('AppLogger', () {
    final lines = <String>[];
    final errors = <Object?>[];
    final original = AppLogger.sink;

    setUp(() {
      lines.clear();
      errors.clear();
      AppLogger.sink = (message, tag, error, stack) {
        lines.add(message);
        errors.add(error);
      };
    });
    tearDown(() => AppLogger.sink = original);

    test('every level redacts its line', () {
      const secret = 'token=$jwt mail=a@b.co phone=0591234567';
      AppLogger.info(secret);
      AppLogger.debug(secret);
      AppLogger.warning(secret);
      AppLogger.error(secret);

      expect(lines, hasLength(4));
      for (final line in lines) {
        expect(line, isNot(contains('eyJ')));
        expect(line, isNot(contains('a@b.co')));
        expect(line, isNot(contains('0591234567')));
      }
    });

    test('the error passed with a line is redacted too', () {
      AppLogger.error('failed', error: Exception('no user a@b.co'));
      expect(errors.single, 'Exception: no user <redacted-email>');
    });
  });
}
