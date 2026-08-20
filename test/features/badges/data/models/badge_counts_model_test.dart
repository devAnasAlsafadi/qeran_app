import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/badges/data/models/badge_counts_model.dart';
import 'package:qeran/features/badges/domain/entities/badge_tab_keys.dart';

/// The badge contract is deliberately open — the server may add keys, omits
/// every zero, and the route's envelope shape is not guaranteed. These pin
/// that none of that can throw, because a parser that crashes over decoration
/// would take a whole shell's navigation with it.
void main() {
  group('shape tolerance', () {
    test('reads a bare dict', () {
      final counts = BadgeCountsModel.fromJson({
        BadgeTabKeys.likes: 3,
        BadgeTabKeys.chat: 7,
      });

      expect(counts.likes, 3);
      expect(counts.chat, 7);
    });

    test('unwraps the standard envelope', () {
      final counts = BadgeCountsModel.fromJson({
        'status': 1,
        'message': 'ok',
        'data': {BadgeTabKeys.cases: 2},
      });

      expect(counts.cases, 2);
    });

    // A bare dict has no `data` key of its own in practice, but if one ever
    // arrived carrying a number we must not mistake it for an envelope.
    test('a non-map `data` does not trigger unwrapping', () {
      final counts = BadgeCountsModel.fromJson({
        'data': 5,
        BadgeTabKeys.likes: 1,
      });

      expect(counts.likes, 1);
    });

    test('null and non-map bodies read as no badges', () {
      expect(BadgeCountsModel.fromJson(null).likes, 0);
      expect(BadgeCountsModel.fromJson('nope').likes, 0);
      expect(BadgeCountsModel.fromJson(<int>[1, 2]).likes, 0);
    });
  });

  group('per-key tolerance', () {
    test('an absent key is zero, not an error', () {
      final counts = BadgeCountsModel.fromJson({BadgeTabKeys.likes: 4});

      expect(counts.chat, 0);
      expect(counts.notifications, 0);
      expect(counts.has(BadgeTabKeys.chat), isFalse);
    });

    // The whole reason the entity holds a map instead of named fields: a key
    // shipped by a newer server must survive an older client untouched.
    test('an unknown key is kept and readable, never thrown on', () {
      final counts = BadgeCountsModel.fromJson({
        'somethingNewUnread': 9,
        BadgeTabKeys.likes: 1,
      });

      expect(counts.of('somethingNewUnread'), 9);
      expect(counts.likes, 1);
    });

    test('numeric strings and doubles are read as counts', () {
      final counts = BadgeCountsModel.fromJson({
        BadgeTabKeys.likes: '3',
        BadgeTabKeys.chat: 2.0,
      });

      expect(counts.likes, 3);
      expect(counts.chat, 2);
    });

    test('unreadable, negative and zero values all read as no badge', () {
      final counts = BadgeCountsModel.fromJson({
        BadgeTabKeys.likes: 'not a number',
        BadgeTabKeys.chat: -4,
        BadgeTabKeys.cases: 0,
        BadgeTabKeys.users: null,
        BadgeTabKeys.conversations: double.nan,
      });

      expect(counts.likes, 0);
      expect(counts.chat, 0);
      expect(counts.cases, 0);
      expect(counts.users, 0);
      expect(counts.conversations, 0);
    });
  });
}
