import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/badges/domain/entities/badge_tab_keys.dart';
import 'package:qeran/features/badges/domain/entities/nav_badge_tabs.dart';

/// Opening a tab acknowledges its badge — except where it must not. Neither
/// shell can be pumped in a widget test, so these are the only guard on the
/// exclusions, and the exclusions are the part a later edit would quietly undo.
void main() {
  group('the user shell', () {
    test('Likes and Profile acknowledge their badges', () {
      expect(NavBadgeTabs.user[1], BadgeTabKeys.likes);
      expect(NavBadgeTabs.user[3], BadgeTabKeys.account);
    });

    // Messages HAS a badge. It clears one conversation at a time, through the
    // hub's MarkAsRead — clearing it on tab open would bury messages nobody
    // opened.
    test('Messages does not, though it carries one', () {
      expect(NavBadgeTabs.user[2], isNull);
      expect(NavBadgeTabs.user.values, isNot(contains(BadgeTabKeys.chat)));
    });

    // Discovery carries no badge at all — nothing to acknowledge.
    test('Discovery has nothing to clear', () {
      expect(NavBadgeTabs.user[0], isNull);
    });

    test('nothing else is wired', () {
      expect(NavBadgeTabs.user.keys, unorderedEquals([1, 3]));
    });
  });

  group('the matchmaker shell', () {
    test('Users and Cases acknowledge their badges', () {
      expect(NavBadgeTabs.matchmaker[1], BadgeTabKeys.users);
      expect(NavBadgeTabs.matchmaker[2], BadgeTabKeys.cases);
    });

    // Same rule as the user app's Messages, same reason.
    test('Conversations does not, though it carries one', () {
      expect(NavBadgeTabs.matchmaker[3], isNull);
      expect(
        NavBadgeTabs.matchmaker.values,
        isNot(contains(BadgeTabKeys.conversations)),
      );
    });

    // Both are documented as permanently zero, so neither renders a dot.
    test('Dashboard and Explore have nothing to clear', () {
      expect(NavBadgeTabs.matchmaker[0], isNull);
      expect(NavBadgeTabs.matchmaker[4], isNull);
    });

    test('nothing else is wired', () {
      expect(NavBadgeTabs.matchmaker.keys, unorderedEquals([1, 2]));
    });
  });

  // The two roles read the same endpoint and must never share a key: a tab
  // acknowledged in one shell has no business clearing in the other.
  test('the two maps share no badge key', () {
    expect(
      NavBadgeTabs.user.values.toSet().intersection(
        NavBadgeTabs.matchmaker.values.toSet(),
      ),
      isEmpty,
    );
  });
}
