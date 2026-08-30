import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/notifications/domain/entities/notification_audience.dart';
import 'package:qeran/features/notifications/domain/entities/notification_item.dart';
import 'package:qeran/features/notifications/domain/entities/notification_type.dart';

/// The wrapper exists to keep two states apart that an enum would fold into
/// one `unknown`: nobody was named, and someone was named that this build does
/// not know. The second is the state Tariq's not-yet-given sender/receiver
/// values will arrive in, so losing the distinction would make a new server
/// audience indistinguishable from a payload that carried none.
NotificationItem _item(Map<String, dynamic> data) => NotificationItem(
  id: 1,
  titleAr: 'ع',
  titleEn: 'en',
  bodyAr: 'ع',
  bodyEn: 'en',
  type: NotificationType.match,
  data: data,
  createdAt: null,
);

void main() {
  // The common case, and the one that must stay harmless: every notification
  // predating the field arrives this way.
  group('nobody was named', () {
    for (final raw in const <Object?>[null, '', '   ', '\n']) {
      test('${raw == null ? 'null' : '"$raw"'} is absent', () {
        final audience = NotificationAudience.fromWire(raw);

        expect(audience.isAbsent, isTrue);
        expect(audience.isMatchmaker, isFalse);
        expect(
          audience.isUnrecognised,
          isFalse,
          reason:
              'an absent audience read as "named by someone I do not know" — '
              'the two mean opposite things to a caller deciding whether to '
              'act.',
        );
      });
    }

    test('and it equals the shared absent value', () {
      expect(NotificationAudience.fromWire(null), NotificationAudience.absent);
    });
  });

  group('the one value confirmed against a real payload', () {
    // Case and padding come off the wire however the server writes them; the
    // guard that keeps the matchmaker shell out of a user's notification must
    // not turn on their spelling.
    for (final raw in const [
      'matchmaker',
      'Matchmaker',
      'MATCHMAKER',
      '  matchmaker  ',
    ]) {
      test('"$raw" is the matchmaker', () {
        final audience = NotificationAudience.fromWire(raw);

        expect(audience.isMatchmaker, isTrue);
        expect(audience.isAbsent, isFalse);
        expect(audience.isUnrecognised, isFalse);
      });
    }
  });

  // THE one the wrapper exists for. When the formal step names its two
  // recipients, they land here first — recognised as addressed to SOMEBODY,
  // just not to anyone this build can place.
  group('named, but not by a name this build knows', () {
    test('an unknown audience is neither absent nor the matchmaker', () {
      final audience = NotificationAudience.fromWire('some_future_value');

      expect(audience.isUnrecognised, isTrue);
      expect(audience.isAbsent, isFalse);
      expect(audience.isMatchmaker, isFalse);
    });

    test('the value survives the trip so whoever learns it can read it', () {
      expect(
        NotificationAudience.fromWire('Some_Future_Value').raw,
        'some_future_value',
      );
    });

    // Unreadable is a different thing from missing, here as everywhere else
    // in this feature.
    test('a non-string value is unrecognised rather than dropped', () {
      expect(NotificationAudience.fromWire(7).isUnrecognised, isTrue);
    });
  });

  group('the entity reads it off the payload', () {
    test('present', () {
      expect(_item({'audience': 'matchmaker'}).audience.isMatchmaker, isTrue);
    });

    test('missing key', () {
      expect(_item(const {}).audience.isAbsent, isTrue);
    });
  });
}
