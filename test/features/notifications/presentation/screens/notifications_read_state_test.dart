import 'package:dartz/dartz.dart';
// easy_localization re-exports intl, whose TextDirection collides with
// dart:ui's — the one Directionality actually takes.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/features/badges/domain/entities/badge_tab_keys.dart';
import 'package:qeran/features/badges/domain/usecases/get_badges_usecase.dart';
import 'package:qeran/features/badges/domain/usecases/mark_tab_seen_usecase.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/features/notifications/domain/entities/notification_item.dart';
import 'package:qeran/features/notifications/domain/entities/notification_type.dart';
import 'package:qeran/features/notifications/domain/entities/notifications_page.dart';
import 'package:qeran/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:qeran/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:qeran/features/notifications/presentation/blocs/notification_read_cubit.dart';
import 'package:qeran/features/notifications/presentation/blocs/notifications_cubit.dart';
import 'package:qeran/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:qeran/features/notifications/presentation/widgets/notification_inbox_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The inbox has no backend PER-ROW read-state, so "read" is local — and it is
/// a DIFFERENT thing from the bell's "seen":
/// * seen → the bell's server-side count, marked on the way OUT of the screen
/// * read → the row treatment, marked by opening a row or sweeping the lot
///
/// These pin that split, because collapsing the two is what made the earlier
/// version pointless: marking everything read the instant the list appeared
/// left nothing for the user to see or act on.

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

NotificationItem _item(int id) => NotificationItem(
  id: id,
  titleAr: 'عنوان $id',
  titleEn: 'Title $id',
  bodyAr: 'نص $id',
  bodyEn: 'Body $id',
  type: NotificationType.general,
  data: const {},
  createdAt: null,
);

class _FakeRepo extends Fake implements NotificationsRepository {
  @override
  Future<Either<Failure, NotificationsPage>> getNotifications({
    required int page,
    required int pageSize,
  }) async => Right(
    NotificationsPage(
      items: page == 1 ? [_item(3), _item(2), _item(1)] : const [],
      hasMore: false,
    ),
  );
}

class _FakeGetBadges extends Fake implements GetBadgesUseCase {}

class _FakeMarkTabSeen extends Fake implements MarkTabSeenUseCase {}

/// Records which tabs the screen marked seen, without touching the network.
class _SpyBadgesCubit extends BadgesCubit {
  _SpyBadgesCubit()
    : super(getBadges: _FakeGetBadges(), markTabSeen: _FakeMarkTabSeen());

  final List<String> seenTabs = [];

  @override
  Future<void> markSeen(String tabKey) async => seenTabs.add(tabKey);
}

late _SpyBadgesCubit _badge;

Future<void> _pumpInbox(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = SharedPrefService(await SharedPreferences.getInstance());
  final usecase = GetNotificationsUseCase(_FakeRepo());

  _badge = _SpyBadgesCubit();
  sl.registerFactory<NotificationsCubit>(
    () => NotificationsCubit(getNotifications: usecase),
  );
  sl.registerLazySingleton<NotificationReadCubit>(
    () => NotificationReadCubit(prefs: prefs),
  );
  sl.registerLazySingleton<BadgesCubit>(() => _badge);

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: const NotificationsScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

bool _isUnread(WidgetTester tester, int id) => tester
    .widgetList<NotificationInboxTile>(find.byType(NotificationInboxTile))
    .firstWhere((t) => t.notification.id == id)
    .isUnread;

/// The row's own surface — the Material the tile paints itself on.
Material _surfaceOf(WidgetTester tester, int id) => tester.widget<Material>(
  find
      .descendant(
        of: find.byWidgetPredicate(
          (w) => w is NotificationInboxTile && w.notification.id == id,
        ),
        matching: find.byType(Material),
      )
      .first,
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() async => sl.reset());

  testWidgets('rows start unread — arriving is not reading', (tester) async {
    await _pumpInbox(tester);

    expect(find.byType(NotificationInboxTile), findsNWidgets(3));
    for (final id in [1, 2, 3]) {
      expect(_isUnread(tester, id), isTrue);
    }
    expect(find.byType(NotificationUnreadDot), findsNWidgets(3));
  });

  // The row TREATMENT, pinned. Both states are paper: unread is separated by
  // lift + the gold dot, never by a tint. An earlier version washed unread rows
  // in cream, which against the cream canvas behind the feed read as two shades
  // of the same beige rather than as a state.
  testWidgets('both states are paper — unread is lifted, not tinted', (
    tester,
  ) async {
    await _pumpInbox(tester);

    expect(_surfaceOf(tester, 2).color, QeranColors.paper);
    expect(_surfaceOf(tester, 2).elevation, 2);

    await tester.tap(find.text('Title 2'));
    await tester.pumpAndSettle();

    // Same surface once read — only the lift and the dot go away.
    expect(_surfaceOf(tester, 2).color, QeranColors.paper);
    expect(_surfaceOf(tester, 2).elevation, 0);
    expect(_surfaceOf(tester, 2).shadowColor, isNot(Colors.black));
  });

  testWidgets('opening one row reads that row only', (tester) async {
    await _pumpInbox(tester);

    await tester.tap(find.text('Title 2'));
    await tester.pumpAndSettle();

    expect(_isUnread(tester, 2), isFalse);
    expect(_isUnread(tester, 1), isTrue);
    expect(_isUnread(tester, 3), isTrue);
  });

  testWidgets('the sweep clears every row at once', (tester) async {
    await _pumpInbox(tester);

    await tester.tap(find.byIcon(Icons.done_all_rounded));
    await tester.pumpAndSettle();

    for (final id in [1, 2, 3]) {
      expect(_isUnread(tester, id), isFalse);
    }
    expect(find.byType(NotificationUnreadDot), findsNothing);
  });

  testWidgets('the sweep stops being offered once nothing is unread', (
    tester,
  ) async {
    await _pumpInbox(tester);
    expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.done_all_rounded));
    await tester.pumpAndSettle();

    // A button that can no longer do anything is not left sitting there.
    expect(find.byIcon(Icons.done_all_rounded), findsNothing);
  });

  testWidgets('the bell is marked seen on the way OUT, not on load', (
    tester,
  ) async {
    await _pumpInbox(tester);

    // Still on the screen: the badge must survive long enough to be seen.
    expect(_badge.seenTabs, isEmpty);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();

    expect(_badge.seenTabs, [BadgeTabKeys.notifications]);
  });
}
