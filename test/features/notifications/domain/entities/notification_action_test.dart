import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/notifications/domain/entities/notification_action.dart';

/// The wire strings, and nothing but the wire strings.
///
/// These members were held back for an arc because the server's values were
/// not documented and a member spelled from a paraphrase is worse than no
/// member at all — it draws a confident glyph on the wrong event. They arrived
/// verbatim on 2026-08-29, so this pins them against the spelling rather than
/// against our memory of it: `formal_step_requested`, not `formalStepRequested`
/// or `formal-step-requested`.
///
/// A misspelled arm does not fail anywhere else. It silently returns [none],
/// the tile draws the neutral bell, and the notification looks merely
/// unrecognised — which is exactly what it looked like before the members
/// existed.
const _wire = {
  'like': NotificationAction.like,
  'like_accepted': NotificationAction.likeAccepted,
  'photo_exchange_requested': NotificationAction.photoExchangeRequested,
  'photo_exchange_accepted': NotificationAction.photoExchangeAccepted,
  'photo_exchange_rejected': NotificationAction.photoExchangeRejected,
  'formal_step_requested': NotificationAction.formalStepRequested,
  'formal_step_accepted': NotificationAction.formalStepAccepted,
  'case_ended': NotificationAction.caseEnded,
  'case_cancelled': NotificationAction.caseCancelled,
  'profile_approved': NotificationAction.profileApproved,
  'profile_rejected': NotificationAction.profileRejected,
  'compatibility_case_updated': NotificationAction.compatibilityCaseUpdated,
};

void main() {
  group('the server spelling', () {
    for (final entry in _wire.entries) {
      test('"${entry.key}"', () {
        expect(NotificationAction.fromWire(entry.key), entry.value);
      });
    }

    test('every member except none has a wire string that reaches it', () {
      final reached = _wire.values.toSet();
      final missing = NotificationAction.values
          .where((a) => a != NotificationAction.none)
          .where((a) => !reached.contains(a))
          .map((a) => a.name);

      expect(
        missing,
        isEmpty,
        reason:
            'a member no wire string parses to is unreachable — it can never '
            'be drawn, and its glyph is decoration.',
      );
    });
  });

  // Three endings, three names. `case_ended` is the DECLINED formal step and
  // only that; a cancellation and a recorded outcome are their own events, and
  // reading one as another reports the wrong thing with full confidence.
  group('the three endings stay apart', () {
    test('a declined formal step', () {
      expect(
        NotificationAction.fromWire('case_ended'),
        NotificationAction.caseEnded,
      );
    });

    test('a called-off case', () {
      expect(
        NotificationAction.fromWire('case_cancelled'),
        NotificationAction.caseCancelled,
      );
    });

    test('a recorded outcome', () {
      expect(
        NotificationAction.fromWire('compatibility_case_updated'),
        NotificationAction.compatibilityCaseUpdated,
      );
    });
  });

  group('anything else claims nothing', () {
    for (final raw in const <String?>[
      null,
      '',
      'formalStepRequested',
      'formal-step-requested',
      'case_closed',
      'some_future_event',
    ]) {
      test(raw == null ? 'null' : '"$raw"', () {
        expect(NotificationAction.fromWire(raw), NotificationAction.none);
      });
    }

    // Case is normalised, so a server that shouts still lands correctly.
    test('the spelling is matched whatever its case', () {
      expect(
        NotificationAction.fromWire('CASE_ENDED'),
        NotificationAction.caseEnded,
      );
    });
  });
}
