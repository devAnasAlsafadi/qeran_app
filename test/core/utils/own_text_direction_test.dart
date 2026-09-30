import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/utils/own_text_direction.dart';

void main() {
  test('an Arabic name reads right to left, a Latin one left to right', () {
    expect(ownTextDirection('هدى الخطيب'), TextDirection.rtl);
    expect(ownTextDirection('Huda Al-Khatib'), TextDirection.ltr);
    expect(ownTextDirection('שרה'), TextDirection.rtl);
  });

  test('the first letter decides, whatever comes before it', () {
    expect(ownTextDirection('🌸 هدى'), TextDirection.rtl);
    expect(ownTextDirection('🌸 Huda'), TextDirection.ltr);
    expect(ownTextDirection('(12) هدى'), TextDirection.rtl);
    expect(ownTextDirection('١٢ Huda'), TextDirection.ltr);
  });

  test('a mixed name reads in the direction it starts in', () {
    expect(ownTextDirection('هدى Huda'), TextDirection.rtl);
    expect(ownTextDirection('Huda هدى'), TextDirection.ltr);
  });

  test('an explicit direction mark counts as the first letter', () {
    expect(ownTextDirection('‏Huda'), TextDirection.rtl);
    expect(ownTextDirection('‎هدى'), TextDirection.ltr);
  });

  test('no letter at all leaves the UI\'s direction', () {
    expect(ownTextDirection(''), isNull);
    expect(ownTextDirection('12345'), isNull);
    expect(ownTextDirection('🌸🌸'), isNull);
  });
}
