import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/features/matchmaker/notifications/domain/entities/matchmaker_notification.dart';
import 'package:qeran/features/matchmaker/notifications/presentation/blocs/matchmaker_notification_read_cubit.dart';
import 'package:qeran/features/matchmaker/notifications/presentation/widgets/matchmaker_notification_tile.dart';
import 'package:qeran/features/notifications/presentation/widgets/notification_inbox_tile.dart'
    show NotificationUnreadDot;
import 'package:shared_preferences/shared_preferences.dart';

/// The matchmaker inbox has no backend read-state and no per-id endpoint, so
/// "read" is a single local watermark: anything newer than the last visit is
/// unread.
///
/// The load-bearing rule these pin is that the watermark the ROWS render
/// against is frozen at mount. The user app shipped the other version once —
/// marking everything read the instant the list appeared — and reverted it,
/// because it leaves nothing for the user to see.

Future<SharedPrefService> _prefs([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return SharedPrefService(await SharedPreferences.getInstance());
}

MatchmakerNotification _item(int id) => MatchmakerNotification(
  id: id,
  titleAr: 'عنوان $id',
  titleEn: 'Title $id',
  bodyAr: 'نص $id',
  bodyEn: 'Body $id',
  type: MatchmakerNotificationType.general,
  data: const {},
  createdAt: null,
);

Material _surfaceOf(WidgetTester tester) => tester.widget<Material>(
  find
      .descendant(
        of: find.byType(MatchmakerNotificationTile),
        matching: find.byType(Material),
      )
      .first,
);

Future<void> _pumpTile(WidgetTester tester, {required bool isUnread}) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MatchmakerNotificationTile(
            notification: _item(1),
            isArabic: false,
            isUnread: isUnread,
          ),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('read watermark', () {
    test('a fresh install has read nothing', () async {
      final cubit = MatchmakerNotificationReadCubit(prefs: await _prefs());
      await cubit.load();

      expect(cubit.state, 0);
      expect(cubit.isUnread(1), isTrue);
    });

    test('restores the stored watermark and splits on it', () async {
      final cubit = MatchmakerNotificationReadCubit(
        prefs: await _prefs({StorageKeys.matchmakerNotifReadWatermark: 5}),
      );
      await cubit.load();

      expect(cubit.isUnread(5), isFalse, reason: 'at the watermark = read');
      expect(cubit.isUnread(4), isFalse);
      expect(cubit.isUnread(6), isTrue);
    });

    // THE test. Marking read must not disturb what is on screen, or the visit
    // the user just started shows them nothing.
    test('marking read persists WITHOUT clearing the rows in front of the '
        'user', () async {
      final prefs = await _prefs({StorageKeys.matchmakerNotifReadWatermark: 5});
      final cubit = MatchmakerNotificationReadCubit(prefs: prefs);
      await cubit.load();

      await cubit.markAllRead(9);

      // Still highlighted for this visit...
      expect(cubit.state, 5);
      expect(cubit.isUnread(9), isTrue);
      // ...but the next mount starts clean.
      expect(
        await prefs.get<int>(StorageKeys.matchmakerNotifReadWatermark),
        9,
      );

      final next = MatchmakerNotificationReadCubit(prefs: prefs);
      await next.load();
      expect(next.isUnread(9), isFalse);
    });

    test('monotonic — a late older page cannot un-read anything', () async {
      final prefs = await _prefs({StorageKeys.matchmakerNotifReadWatermark: 9});
      final cubit = MatchmakerNotificationReadCubit(prefs: prefs);
      await cubit.load();

      await cubit.markAllRead(4);

      expect(
        await prefs.get<int>(StorageKeys.matchmakerNotifReadWatermark),
        9,
      );
    });

    // The user app keeps its own watermark under a different key; a matchmaker
    // reading the shared inbox must not inherit it.
    test('does not touch the user-app watermark', () async {
      final prefs = await _prefs({StorageKeys.notifReadWatermark: 3});
      final cubit = MatchmakerNotificationReadCubit(prefs: prefs);
      await cubit.load();
      await cubit.markAllRead(9);

      expect(cubit.state, 0, reason: 'the user key is not read from');
      expect(await prefs.get<int>(StorageKeys.notifReadWatermark), 3);
    });
  });

  group('tile treatment', () {
    testWidgets('unread lifts off paper and carries the dot', (tester) async {
      await _pumpTile(tester, isUnread: true);

      expect(_surfaceOf(tester).color, QeranColors.paper);
      expect(_surfaceOf(tester).elevation, 2);
      expect(_surfaceOf(tester).shadowColor, isNot(Colors.black));
      expect(find.byType(NotificationUnreadDot), findsOneWidget);
    });

    testWidgets('read is the same paper, flat and undotted', (tester) async {
      await _pumpTile(tester, isUnread: false);

      // Same surface as unread — the state is carried by lift and dot, never
      // by a tint. Rows used to be transparent over the cream canvas.
      expect(_surfaceOf(tester).color, QeranColors.paper);
      expect(_surfaceOf(tester).elevation, 0);
      expect(find.byType(NotificationUnreadDot), findsNothing);
    });
  });
}
