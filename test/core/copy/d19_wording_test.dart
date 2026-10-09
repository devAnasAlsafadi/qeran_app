import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// D19, the Phase 4 copy pass (`docs/app-map/15-wording-table.md`): between
/// members the word is «اهتمام» / "interest". «إعجاب» / "like" stays on
/// Community's posts, comments and replies. Read from the shipped files, so a
/// string that drifts back fails here, whichever screen shows it.

Map<String, dynamic> _load(String locale) =>
    jsonDecode(File('assets/translations/$locale.json').readAsStringSync())
        as Map<String, dynamic>;

/// The value at a dotted [path], or null when any part is missing.
Object? _at(Map<String, dynamic> json, String path) {
  Object? node = json;
  for (final part in path.split('.')) {
    if (node is! Map<String, dynamic>) return null;
    node = node[part];
  }
  return node;
}

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

/// The 36 member-to-member keys the pass reworded (the 39 less the 3 deleted).
const _d19 = [
  'discovery.action_like_label',
  'discovery.like_already_pending',
  'discovery.like_gender_mismatch',
  'profile.status_pending_review_like',
  'profile.reaction_like_success',
  'likes.tab_sent',
  'likes.tab_received',
  'likes.action_accepted_success',
  'likes.action_rejected_success',
  'likes.empty_sent_title',
  'likes.empty_sent_subtitle',
  'likes.empty_received_title',
  'likes.empty_received_subtitle',
  'likes.error_title',
  'likes.locked_title',
  'likes.locked_subtitle',
  'likes.matches_empty_subtitle',
  'profile.status_pending_review_accept',
  'subscriptions.feature_likes_label',
  'subscriptions.paywall_like_title',
  'subscriptions.paywall_like_body',
  'subscriptions.paywall_likes_exhausted_title',
  'subscriptions.paywall_likes_exhausted_body',
  'subscriptions.paywall_accept_title',
  'subscriptions.paywall_accept_body',
  'notifications.empty_subtitle',
  'settings.delete_account_consequence_data',
  'matchmaker.interests_tab_incoming',
  'matchmaker.interests_tab_outgoing',
  'matchmaker.interests_empty_incoming_title',
  'matchmaker.interests_empty_outgoing_title',
  'matchmaker.interests_archive_type_like',
  'matchmaker.cases_like_accepted_at',
  'matchmaker.cases_stage_like_accepted',
  'matchmaker.cases_field_like_accepted',
  'matchmaker.empty_cases_message',
];

/// Community's own likes, on posts, comments and replies (D15).
const _community = [
  'community.like',
  'community.like_failed',
  'community.her.like_failed',
  'community.read_only_like',
];

final _like = RegExp(r'\blik(e|es|ed)\b', caseSensitive: false);
final _match = RegExp(r'\bmatch(es|ed)?\b', caseSensitive: false);

void main() {
  final ar = _load('ar');
  final en = _load('en');

  test('the 36 member keys say «اهتمام», never «إعجاب» / like', () {
    expect(_d19, hasLength(36));
    for (final key in _d19) {
      final arabic = _at(ar, key)! as String;
      expect(arabic, isNot(matches('إعجاب|أعجب')), reason: key);
      expect(_at(en, key)! as String, isNot(matches(_like)), reason: key);
    }
  });

  test('Community still says «إعجاب» / like', () {
    for (final key in [..._community, 'community.gate_pending']) {
      expect(_at(ar, key)! as String, contains('إعجاب'), reason: key);
    }
    for (final key in _community) {
      expect(_at(en, key)! as String, matches(_like), reason: key);
    }
  });

  // «اهتماماتك» reads as "your hobbies"; «الإهتمامات» is misspelled.
  test('no string says «اهتماماتك» or «الإهتمامات»', () {
    for (final (path, value) in _strings(ar)) {
      expect(value, isNot(matches('اهتماماتك|الإهتمام')), reason: path);
    }
  });

  test('member interest is never a «تطابق» / "match"', () {
    const sections = ['likes.', 'matchmaker.interests_', 'notifications.'];
    const keys = [
      'auth.photo_privacy_note',
      'discovery.filter_subtitle',
      'profile.upsell_subtitle',
      'profile.upsell_teaser_1',
      'matchmaker.explore_no_results_filtered_title',
    ];
    bool covered(String path) =>
        keys.contains(path) || sections.any(path.startsWith);
    // Her Explore's Arabic keeps «تطابق» as a verb: results that match filters.
    bool arabic(String path) =>
        covered(path) && path != 'matchmaker.explore_no_results_filtered_title';
    for (final (path, value) in _strings(ar).where((e) => arabic(e.$1))) {
      expect(value, isNot(contains('تطابق')), reason: path);
    }
    for (final (path, value) in _strings(en).where((e) => covered(e.$1))) {
      expect(value, isNot(matches(_match)), reason: path);
    }
  });

  test('the unused old-wording keys are gone', () {
    const gone = [
      'likes.action_subscription_required',
      'likes.locked_card_title',
      'subscriptions.feature_likes',
      'discovery.upgrade_banner_message',
      'discovery.upgrade_banner_cta',
      'subscriptions.status_free_title',
      'subscriptions.status_free_body',
    ];
    for (final key in gone) {
      expect(_at(ar, key), isNull, reason: key);
      expect(_at(en, key), isNull, reason: key);
    }
  });
}
