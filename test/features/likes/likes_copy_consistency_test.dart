import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Spelling invariants for the shipped Arabic in the `likes` section.
///
/// This exists because the fix alone does not hold. The matchmaker's title is
/// «الخطّابة» with a shadda on the ط, and `likes` spelled it BOTH ways for
/// months — seven keys with, five without — while every assertion in the suite
/// passed. Nothing reads a string's spelling, so nothing noticed, and the
/// inconsistency was found by grepping rather than by a failing test.
///
/// Reverting any one of the five is a change no other test in this repo
/// catches. This is the one that does.
Map<String, dynamic> _section(String locale, String section) {
  final file = File('assets/translations/$locale.json');
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return json[section] as Map<String, dynamic>;
}

void main() {
  // The bare form, i.e. the ط NOT followed by a shadda. Present in a shipped
  // string, it means the diacritic was dropped.
  const plain = 'خطابة';
  const plural = 'خطابات';

  test('every likes string spells the matchmaker with the shadda', () {
    final offenders = <String>[];
    _section('ar', 'likes').forEach((key, value) {
      if (value is String && (value.contains(plain) || value.contains(plural))) {
        offenders.add('$key = $value');
      }
    });

    expect(
      offenders,
      isEmpty,
      reason:
          'spell it «الخطّابة», as the rest of this section and the whole of '
          'matchmaker/chat/profile already do:\n${offenders.join('\n')}',
    );
  });

  // Guards the guard: if the word ever leaves this section entirely the test
  // above would pass vacuously and stop meaning anything.
  test('the word is actually present in the section it polices', () {
    final withShadda = _section(
      'ar',
      'likes',
    ).values.whereType<String>().where((v) => v.contains('الخطّابة')).length;

    expect(
      withShadda,
      greaterThan(5),
      reason: 'likes should still be talking about the matchmaker',
    );
  });

  // ⚠️ Deliberately scoped to `likes`. The same five-key problem exists in
  // `onboarding` — `mediation.title`, `mediation.search_cta`,
  // `mediation.block_sent_label`, `roadmap.badge_consent`,
  // `roadmap.badge_orderly` — found while fixing this one and left alone,
  // because widening a compatibility-journey commit into the onboarding
  // feature is how unrelated changes get buried. Logged for its own pass;
  // widen this test to walk the whole file when that lands.
}
