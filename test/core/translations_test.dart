import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the translation files against the two ways a rename goes wrong.
///
/// Written when five `likes.matches_formal_step_*` keys moved to
/// `likes.matches_case_*` because cancel and a declined formal step reach the
/// same ending and should not drift into two sentences for one consequence.
/// A rename like that fails in silence twice over: a key left behind in the
/// JSON is dead weight nobody notices, and a key renamed in one locale only
/// makes the app fall back to printing the key ID at the reader.
///
/// `flutter analyze` catches neither — `LocaleKeys` is generated FROM these
/// files, so it agrees with whatever they say.

Map<String, dynamic> _load(String locale) =>
    jsonDecode(File('assets/translations/$locale.json').readAsStringSync())
        as Map<String, dynamic>;

/// Every LEAF key as a dotted path, matching how `LocaleKeys` names them.
///
/// Recursive rather than two levels deep: most sections are flat, but
/// `onboarding.essence.*` nests one further, and a two-level walk reports its
/// leaves as missing while quietly adding a key (`onboarding.essence`) that
/// does not exist.
Set<String> _flatten(Map<String, dynamic> json, [String prefix = '']) {
  final out = <String>{};
  json.forEach((key, value) {
    final path = prefix.isEmpty ? key : '$prefix.$key';
    if (value is Map<String, dynamic>) {
      out.addAll(_flatten(value, path));
    } else {
      out.add(path);
    }
  });
  return out;
}

/// Every `LocaleKeys.x` referenced by shipped code, as the `section.key` the
/// generated constant holds.
Set<String> _referenced() {
  final used = <String>{};
  final generated = File('lib/generated/locale_keys.g.dart').readAsStringSync();
  final decl = RegExp(r"static const (\w+) = '([^']+)'");
  final byName = <String, String>{
    for (final m in decl.allMatches(generated)) m.group(1)!: m.group(2)!,
  };

  final usage = RegExp(r'LocaleKeys\.(\w+)');
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('locale_keys.g.dart')) continue;
    for (final m in usage.allMatches(entity.readAsStringSync())) {
      final path = byName[m.group(1)!];
      if (path != null) used.add(path);
    }
  }
  return used;
}

void main() {
  test('ar and en define exactly the same keys', () {
    final ar = _flatten(_load('ar'));
    final en = _flatten(_load('en'));

    expect(
      ar.difference(en),
      isEmpty,
      reason: 'in ar but not en — en falls back to printing the key ID',
    );
    expect(en.difference(ar), isEmpty, reason: 'in en but not ar');
  });

  // The keys renamed alongside the cancel path. Named rather than swept
  // because a broad "every key is used" assertion would fail on the keys that
  // are legitimately unused-but-kept, and would have to be suppressed — at
  // which point it stops guarding anything.
  test('the renamed case keys left nothing behind', () {
    const retired = [
      'likes.matches_formal_step_reject_confirm_title',
      'likes.matches_formal_step_reject_confirm_message',
      'likes.matches_formal_step_reject_confirm_action',
      'likes.matches_formal_step_reject_success',
      'likes.matches_formal_step_case_ended',
    ];
    const replacements = [
      'likes.matches_case_end_confirm_title',
      'likes.matches_case_end_confirm_message',
      'likes.matches_case_end_confirm_action',
      'likes.matches_case_ended_success',
      'likes.matches_case_already_ended',
      'likes.matches_case_not_found',
    ];

    for (final locale in ['ar', 'en']) {
      final keys = _flatten(_load(locale));
      for (final key in retired) {
        expect(keys, isNot(contains(key)), reason: '$key orphaned in $locale');
      }
      for (final key in replacements) {
        expect(keys, contains(key), reason: '$key missing from $locale');
      }
    }

    // And each replacement is actually wired to something — a renamed key no
    // caller reads is the same dead weight under a newer name.
    final used = _referenced();
    for (final key in replacements) {
      expect(used, contains(key), reason: '$key is defined but never read');
    }
  });

  test('every key the app reads exists in both locales', () {
    final ar = _flatten(_load('ar'));
    final en = _flatten(_load('en'));
    for (final key in _referenced()) {
      expect(ar, contains(key), reason: '$key read by lib/ but missing from ar');
      expect(en, contains(key), reason: '$key read by lib/ but missing from en');
    }
  });
}
