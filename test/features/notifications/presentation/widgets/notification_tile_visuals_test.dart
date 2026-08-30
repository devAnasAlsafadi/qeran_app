import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/notifications/domain/entities/notification_action.dart';
import 'package:qeran/features/notifications/domain/entities/notification_type.dart';
import 'package:qeran/features/notifications/presentation/widgets/notification_tile_visuals.dart';

/// The glyph a notification wears, and specifically what it wears when the
/// app does not recognise the event.
///
/// `Match` is an overloaded type: a like, a mutual accept, the photo-exchange
/// steps, and — since the compatibility-journey V2 arc — the formal step and
/// the ways a case can end. Those last members arrived from the backend's own
/// verbatim strings; until they did, every one of those notifications took the
/// neutral fallback, which is why the fallback is pinned as hard as the glyphs
/// are.
IconData _icon(NotificationType type, NotificationAction action) =>
    NotificationTileVisuals.of(type, action).icon;

void main() {
  group('a recognised Match event keeps its own glyph', () {
    const expected = {
      NotificationAction.like: Icons.favorite_border_rounded,
      NotificationAction.likeAccepted: Icons.celebration_rounded,
      NotificationAction.photoExchangeRequested: Icons.photo_camera_outlined,
      NotificationAction.photoExchangeAccepted: Icons.photo_camera_outlined,
      NotificationAction.photoExchangeRejected: Icons.photo_camera_outlined,
      NotificationAction.formalStepRequested: Icons.mark_email_unread_outlined,
      NotificationAction.formalStepAccepted: Icons.check_circle_outline,
      NotificationAction.caseEnded: Icons.close_rounded,
      NotificationAction.caseCancelled: Icons.cancel_outlined,
      NotificationAction.compatibilityCaseUpdated: Icons.handshake_rounded,
    };

    for (final entry in expected.entries) {
      test(entry.key.name, () {
        expect(_icon(NotificationType.match, entry.key), entry.value);
      });
    }
  });

  // THE one. It used to be a filled heart, which reads as "someone liked
  // you" — a specific claim, and false for every V2 event. A case-ended
  // notice drew a heart.
  //
  // It now matches what an unrecognised TYPE draws, so unknown looks like
  // unknown at both levels and the glyph asserts nothing the server has not
  // said in the title and body it wrote itself.
  test('an unrecognised Match event claims nothing', () {
    expect(
      _icon(NotificationType.match, NotificationAction.none),
      isNot(Icons.favorite_rounded),
      reason: 'a filled heart says "someone liked you"',
    );
    expect(
      _icon(NotificationType.match, NotificationAction.none),
      _icon(NotificationType.unknown, NotificationAction.none),
      reason: 'unknown should look the same at the action and type levels',
    );
  });

  // Every action that is not a Match action still has to resolve, since the
  // wire pairs type and action independently and a mismatched pair is a
  // payload we must not throw on.
  test('every type x action pair resolves to something', () {
    for (final type in NotificationType.values) {
      for (final action in NotificationAction.values) {
        expect(
          () => NotificationTileVisuals.of(type, action),
          returnsNormally,
          reason: '${type.name} / ${action.name}',
        );
      }
    }
  });

  // Sharing a glyph is how a member stops being distinguishable. Two endings
  // drawn alike is the same defect as an ending borrowing the nearest-looking
  // member — the thing this feature has a standing rule against.
  test('no two recognised Match events wear the same glyph', () {
    const events = [
      NotificationAction.like,
      NotificationAction.likeAccepted,
      NotificationAction.formalStepRequested,
      NotificationAction.formalStepAccepted,
      NotificationAction.caseEnded,
      NotificationAction.caseCancelled,
      NotificationAction.compatibilityCaseUpdated,
    ];
    final glyphs = [
      for (final action in events) _icon(NotificationType.match, action),
    ];

    expect(
      glyphs.toSet(),
      hasLength(events.length),
      reason: 'two of these events are indistinguishable in the inbox',
    );
  });

  // The three endings are three different events and the server names them
  // separately. Swapping two of them tells the member the wrong thing happened
  // with full confidence, which is worse than the neutral bell they replaced.
  test('each ending keeps its own glyph', () {
    expect(
      _icon(NotificationType.match, NotificationAction.caseEnded),
      isNot(_icon(NotificationType.match, NotificationAction.caseCancelled)),
    );
    expect(
      _icon(NotificationType.match, NotificationAction.caseEnded),
      isNot(
        _icon(
          NotificationType.match,
          NotificationAction.compatibilityCaseUpdated,
        ),
      ),
    );
  });

  // Profile is the other overloaded type, and its rule is the stricter one:
  // a rejection never wears red in a matrimony app. Pinned here because the
  // fallback change sits two lines away from it.
  test('a profile rejection stays calm', () {
    expect(
      _icon(NotificationType.profile, NotificationAction.profileRejected),
      Icons.info_outline_rounded,
    );
    expect(
      _icon(NotificationType.profile, NotificationAction.profileApproved),
      Icons.verified_rounded,
    );
  });
}
