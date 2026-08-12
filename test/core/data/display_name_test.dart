import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/data/display_name.dart';

void main() {
  group('parseDisplayName', () {
    test('prefers displayName over every legacy key', () {
      expect(
        parseDisplayName({
          'displayName': 'ديما',
          'name': 'legacy',
          'fullName': 'legacy full',
          'firstName': 'legacy first',
        }),
        'ديما',
      );
    });

    test('falls back through name, fullName, firstName in order', () {
      expect(parseDisplayName({'name': 'a', 'fullName': 'b'}), 'a');
      expect(parseDisplayName({'fullName': 'b', 'firstName': 'c'}), 'b');
      expect(parseDisplayName({'firstName': 'c'}), 'c');
    });

    test('a blank or whitespace value does not win over a real one', () {
      expect(parseDisplayName({'displayName': '   ', 'name': 'real'}), 'real');
      expect(parseDisplayName({'displayName': '', 'fullName': 'real'}), 'real');
    });

    test('trims surrounding whitespace', () {
      expect(parseDisplayName({'displayName': '  ديما  '}), 'ديما');
    });

    test('returns empty when no name key is present', () {
      expect(parseDisplayName({'email': 'a@b.c'}), '');
      expect(parseDisplayName(const {}), '');
    });

    test('coerces a non-string value rather than throwing', () {
      expect(parseDisplayName({'name': 42}), '42');
    });

    test(
      'prefer keys win over name — the interest payloads carry both the peer '
      'name and the row own name, and the peer must be shown',
      () {
        expect(
          parseDisplayName({
            'otherUserName': 'peer',
            'name': 'me',
          }, prefer: const ['otherUserName']),
          'peer',
        );
      },
    );

    test('displayName still outranks a prefer key', () {
      expect(
        parseDisplayName({
          'displayName': 'new',
          'otherUserName': 'peer',
        }, prefer: const ['otherUserName']),
        'new',
      );
    });

    test('realName is never used as a fallback — it must not leak', () {
      // realName is private to the owner. If it ever satisfied this lookup it
      // would surface on cards, chat headers and notifications.
      expect(parseDisplayName({'realName': 'الاسم الحقيقي الكامل'}), '');
    });
  });
}
