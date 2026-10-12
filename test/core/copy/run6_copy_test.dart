import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Anas's run-6 copy (`docs/app-map/17-phase4-review.md`, "Run 6"), read from
/// the shipped files: the shorter ask, which no screen can gender, and the
/// Interests tab that fits its segment.

Map<String, dynamic> _load(String locale) =>
    jsonDecode(File('assets/translations/$locale.json').readAsStringSync())
        as Map<String, dynamic>;

String _at(Map<String, dynamic> json, String section, String key) =>
    (json[section] as Map<String, dynamic>)[key] as String;

void main() {
  final ar = _load('ar');
  final en = _load('en');

  test('the ask: «عن هذا الملف», "Ask my matchmaker"', () {
    expect(
      _at(ar, 'profile', 'share_with_matchmaker_cta'),
      'اسأل خطّابتي عن هذا الملف',
    );
    expect(
      _at(en, 'profile', 'share_with_matchmaker_cta'),
      'Ask my matchmaker',
    );
  });

  test('the tab is «المتبادلة» / "Mutual"; its empty state keeps the full '
      'phrase', () {
    expect(_at(ar, 'likes', 'tab_matches'), 'المتبادلة');
    expect(_at(en, 'likes', 'tab_matches'), 'Mutual');
    expect(
      _at(ar, 'likes', 'matches_empty_title'),
      'لا يوجد اهتمام متبادل بعد',
    );
  });
}
