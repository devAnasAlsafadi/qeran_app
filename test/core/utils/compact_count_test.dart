import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/utils/compact_count.dart';

import '../shipped_strings_rig.dart';

/// Every Arabic plural form of the thousands (§7.1), the cut-not-rounded
/// decimal, and where the decimal stops.
const _arabic = <int, String>{
  0: '0',
  128: '128',
  999: '999',
  1000: 'ألف',
  1250: '1.2 ألف',
  1999: '1.9 ألف',
  2000: 'ألفان',
  3000: '3 آلاف',
  3500: '3.5 ألف', // a fraction is never «آلاف»
  10000: '10 آلاف',
  11000: '11 ألفاً',
  12345: '12.3 ألف',
  99999: '99.9 ألف',
  100000: '100 ألف',
  103000: '103 آلاف',
  123456: '123 ألفاً',
};

const _english = <int, String>{
  999: '999',
  1000: '1K',
  1250: '1.2K',
  2000: '2K',
  12345: '12.3K',
  123456: '123K',
};

void main() {
  setUpAll(initShippedStrings);

  testWidgets('Arabic (A17, B1)', (tester) async {
    final context = await pumpShippedStrings(tester, const Locale('ar'));
    for (final MapEntry(key: count, value: text) in _arabic.entries) {
      expect(formatCompactCount(count, context), text, reason: '$count');
    }
  });

  testWidgets('English', (tester) async {
    final context = await pumpShippedStrings(tester, const Locale('en'));
    for (final MapEntry(key: count, value: text) in _english.entries) {
      expect(formatCompactCount(count, context), text, reason: '$count');
    }
  });
}
