import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _strings(String lang) =>
    jsonDecode(File('assets/translations/$lang.json').readAsStringSync())
        as Map<String, dynamic>;

/// Her feminine variants of shared strings (Q9 of Phase 3): each one stands
/// beside a generic key, reads the same in English, and differs in Arabic —
/// or it isn't a variant at all.
void main() {
  final ar = _strings('ar');
  final en = _strings('en');

  for (final section in ['community', 'report']) {
    final hers = (ar[section] as Map<String, dynamic>)['her'] as Map;

    test('$section.her: every key has a generic twin, the same English, '
        'and its own Arabic', () {
      expect(hers, isNotEmpty);
      for (final key in hers.keys) {
        final arBase = (ar[section] as Map)[key];
        final enBase = (en[section] as Map)[key];
        final enHer = ((en[section] as Map)['her'] as Map)[key];
        expect(arBase, isA<String>(), reason: '$section.$key');
        expect(enHer, enBase, reason: '$section.her.$key');
        expect(hers[key], isNot(arBase), reason: '$section.her.$key');
      }
    });
  }
}
