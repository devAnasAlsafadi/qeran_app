import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// One spelling convention for the whole app (Phase 4 A2, Q6): the straight
/// apostrophe in English, tanween as «اً», and her strings — the matchmaker's —
/// address her in the feminine, the kasra on every second-person «كِ».

Map<String, dynamic> _load(String locale) =>
    jsonDecode(File('assets/translations/$locale.json').readAsStringSync())
        as Map<String, dynamic>;

/// Every string in [json] with its dotted path, plural forms included.
Iterable<(String, String)> _strings(
  Map<String, dynamic> json, [
  String prefix = '',
]) sync* {
  for (final MapEntry(:key, :value) in json.entries) {
    final path = prefix.isEmpty ? key : '$prefix.$key';
    if (value is String) yield (path, value);
    if (value is Map<String, dynamic>) yield* _strings(value, path);
  }
}

/// Her app's strings: everything she alone reads.
bool _hers(String path) =>
    path.startsWith('matchmaker.') || path.startsWith('community.her.');

const _letter = r'ء-ي';
const _mark = r'ً-ْ';

/// A word ending in a bare «ك» (no vowel mark after it).
final _bareKaf = RegExp('[$_letter$_mark]*ك(?![$_letter$_mark])');

/// Words that end in «ك» without it being "your".
const _notSuffix = {
  'اشتراك',
  'الاشتراك',
  'يشترك',
  'مُشارَك',
  'ذلك',
  'تلك',
  'هناك',
};

/// Masculine imperatives and forms her strings once used.
final _masculine = RegExp(
  '(?<![$_letter])(اكتب|تواصل|حاول|جرّب|ابحث|تابع|شارك|اختر|أدخل|أضف|ابدأ|'
  'انتظر|تحقّق|أنت|متأكد)(?![$_letter$_mark])',
);

void main() {
  test('English uses the straight apostrophe', () {
    for (final (path, value) in _strings(_load('en'))) {
      expect(value, isNot(contains('’')), reason: path);
    }
  });

  test('tanween is «اً», never «ًا»', () {
    for (final (path, value) in _strings(_load('ar'))) {
      expect(value, isNot(contains('ًا')), reason: path);
    }
  });

  test('her "your" carries the kasra: «كِ»', () {
    for (final (path, value) in _strings(
      _load('ar'),
    ).where((e) => _hers(e.$1))) {
      final bare = _bareKaf
          .allMatches(value)
          .map((m) => m.group(0)!)
          .where((word) => !_notSuffix.contains(word));
      expect(bare, isEmpty, reason: path);
    }
  });

  test('her strings address her in the feminine', () {
    for (final (path, value) in _strings(
      _load('ar'),
    ).where((e) => _hers(e.$1))) {
      expect(value, isNot(matches(_masculine)), reason: path);
    }
  });
}
