import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/auth/domain/entities/user_entity.dart';
import 'package:qeran/features/profile/domain/entities/profile_entry_source.dart';
import 'package:qeran/features/profile/presentation/widgets/full_profile_body.dart';

/// The like/pass bar on the full-profile screen needs TWO facts to be legal,
/// and the bug this pins was shipping with only one of them checked: the gate
/// asked where the profile was opened FROM and never asked who was looking.
///
/// The matchmaker reuses the member chat screen wholesale, so an entry-only
/// gate put like/pass in front of her on a profile she is merely reviewing —
/// and those buttons are live, posting to /likes and /discovery/skip on her
/// own account.

UserEntity _user({String? role}) =>
    UserEntity(id: 'u', name: 'A', email: 'a@b.c', role: role);

void main() {
  group('canReactFromEntry', () {
    test('a member may react from the chat entry, and only that one', () {
      for (final entry in ProfileEntrySource.values) {
        expect(
          canReactFromEntry(entry, isMatchmaker: false),
          entry == ProfileEntrySource.chat,
          reason: '${entry.name} for a regular member',
        );
      }
    });

    test('a matchmaker may react from NO entry — chat included', () {
      // The regression. Chat is the one that used to slip through.
      for (final entry in ProfileEntrySource.values) {
        expect(
          canReactFromEntry(entry, isMatchmaker: true),
          isFalse,
          reason: '${entry.name} for a matchmaker',
        );
      }
    });

    test('it never fires alongside the share CTA', () {
      // Both are pinned to the same bottom slot, and on `chat` the reaction bar
      // deliberately REPLACES the share button. Either both gates opening or
      // both closing on one entry is a layout bug, not a policy choice.
      for (final entry in ProfileEntrySource.values) {
        final reacts = canReactFromEntry(entry, isMatchmaker: false);
        expect(
          reacts && showShareForEntry(entry),
          isFalse,
          reason: '${entry.name} would stack two pinned CTAs',
        );
      }
    });
  });

  group('UserEntity.isMatchmaker', () {
    test('matches the server role however it is cased', () {
      for (final role in ['Moderator', 'moderator', 'MODERATOR']) {
        expect(_user(role: role).isMatchmaker, isTrue, reason: role);
      }
    });

    test('a member, an unknown role and a missing role are all not one', () {
      expect(_user(role: 'User').isMatchmaker, isFalse);
      expect(_user(role: 'Admin').isMatchmaker, isFalse);
      expect(_user(role: '').isMatchmaker, isFalse);
      expect(_user().isMatchmaker, isFalse);
    });
  });
}
