import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/data/json_parsers.dart';

void main() {
  group('parseNullableInt', () {
    test('int → int', () {
      expect(parseNullableInt(7), 7);
    });
    test('num → toInt (truncates)', () {
      expect(parseNullableInt(7.9), 7);
    });
    test('numeric string → int', () {
      expect(parseNullableInt('42'), 42);
    });
    test('null → null', () {
      expect(parseNullableInt(null), isNull);
    });
    test('non-numeric string → null', () {
      expect(parseNullableInt('hello'), isNull);
    });
    test('bool → null (avoids surprising 0/1 coercion)', () {
      expect(parseNullableInt(true), isNull);
    });
  });

  group('parseInt', () {
    test('uses fallback when unparseable', () {
      expect(parseInt(null), 0);
      expect(parseInt('x', fallback: -1), -1);
    });
  });

  group('parseNullableString', () {
    test('String passthrough', () {
      expect(parseNullableString('hi'), 'hi');
    });
    test('int stringifies', () {
      expect(parseNullableString(12345), '12345');
    });
    test('num stringifies', () {
      expect(parseNullableString(3.14), '3.14');
    });
    test('bool stringifies', () {
      expect(parseNullableString(true), 'true');
    });
    test('Map → null (no [Instance of ...] junk in the model)', () {
      expect(parseNullableString({'k': 'v'}), isNull);
    });
    test('List → null', () {
      expect(parseNullableString([1, 2, 3]), isNull);
    });
    test('null → null', () {
      expect(parseNullableString(null), isNull);
    });
  });

  group('parseString (with fallback)', () {
    test('default fallback is empty string', () {
      expect(parseString(null), '');
    });
    test('custom fallback honored', () {
      expect(parseString(null, fallback: 'x'), 'x');
    });
  });

  group('parseBool', () {
    test('bool passthrough', () {
      expect(parseBool(true), isTrue);
      expect(parseBool(false), isFalse);
    });
    test('1/0 ints coerce', () {
      expect(parseBool(1), isTrue);
      expect(parseBool(0), isFalse);
    });
    test('"true"/"false" strings', () {
      expect(parseBool('true'), isTrue);
      expect(parseBool('False'), isFalse);
    });
    test('null → fallback', () {
      expect(parseBool(null), isFalse);
      expect(parseBool(null, fallback: true), isTrue);
    });
  });

  group('parseNullableDateTime', () {
    test('valid ISO string parses', () {
      final dt = parseNullableDateTime('2026-05-17T10:30:00Z');
      expect(dt, isNotNull);
      expect(dt!.year, 2026);
    });
    test('empty / null / int → null', () {
      expect(parseNullableDateTime(''), isNull);
      expect(parseNullableDateTime(null), isNull);
      expect(parseNullableDateTime(123456789), isNull);
    });
  });
}
