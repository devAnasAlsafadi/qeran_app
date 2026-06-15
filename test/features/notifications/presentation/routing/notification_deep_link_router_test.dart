import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/notifications/presentation/routing/notification_deep_link.dart';

void main() {
  group('NotificationDeepLinkRouter.resolveData — FCM map payload', () {
    test('screen=incoming_likes → Likes tab', () {
      expect(
        NotificationDeepLinkRouter.resolveData({'screen': 'incoming_likes'}),
        isA<OpenLikesTab>(),
      );
    });

    test('screen=matches → Likes tab', () {
      expect(
        NotificationDeepLinkRouter.resolveData({'screen': 'matches'}),
        isA<OpenLikesTab>(),
      );
    });

    test('screen=compatibility-cases → Likes tab', () {
      expect(
        NotificationDeepLinkRouter.resolveData({'screen': 'compatibility-cases'}),
        isA<OpenLikesTab>(),
      );
    });

    test('screen=chat → Messages tab', () {
      expect(
        NotificationDeepLinkRouter.resolveData({'screen': 'chat'}),
        isA<OpenMessagesTab>(),
      );
    });

    test('screen=profile → Profile tab', () {
      expect(
        NotificationDeepLinkRouter.resolveData({'screen': 'profile'}),
        isA<OpenProfileTab>(),
      );
    });

    test('screen is case-insensitive', () {
      expect(
        NotificationDeepLinkRouter.resolveData({'screen': 'CHAT'}),
        isA<OpenMessagesTab>(),
      );
    });

    test('no screen → falls back to data.type (Match → Likes)', () {
      expect(
        NotificationDeepLinkRouter.resolveData({'type': 'Match'}),
        isA<OpenLikesTab>(),
      );
    });

    test('no screen → falls back to data.type (Chat → Messages)', () {
      expect(
        NotificationDeepLinkRouter.resolveData({'type': 'Chat'}),
        isA<OpenMessagesTab>(),
      );
    });

    test('no screen → falls back to data.type (Profile → Profile)', () {
      expect(
        NotificationDeepLinkRouter.resolveData({'type': 'Profile'}),
        isA<OpenProfileTab>(),
      );
    });

    test('unknown screen falls through to type fallback', () {
      // Unrecognised screen but a typed payload still routes by type.
      expect(
        NotificationDeepLinkRouter.resolveData(
          {'screen': 'something_new', 'type': 'Chat'},
        ),
        isA<OpenMessagesTab>(),
      );
    });

    test('General type → no destination', () {
      expect(
        NotificationDeepLinkRouter.resolveData({'type': 'General'}),
        isA<NoDeepLink>(),
      );
    });

    test('Announcement / Offer types → no destination', () {
      expect(
        NotificationDeepLinkRouter.resolveData({'type': 'Announcement'}),
        isA<NoDeepLink>(),
      );
      expect(
        NotificationDeepLinkRouter.resolveData({'type': 'Offer'}),
        isA<NoDeepLink>(),
      );
    });

    test('empty / unknown payload → no destination (never throws)', () {
      expect(
        NotificationDeepLinkRouter.resolveData(<String, dynamic>{}),
        isA<NoDeepLink>(),
      );
      expect(
        NotificationDeepLinkRouter.resolveData({'type': 'wat'}),
        isA<NoDeepLink>(),
      );
    });
  });
}
