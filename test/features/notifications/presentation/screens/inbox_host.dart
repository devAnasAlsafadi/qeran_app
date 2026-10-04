import 'package:dartz/dartz.dart';
// easy_localization re-exports intl, whose TextDirection collides with
// dart:ui's — the one Directionality actually takes.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/widgets/connectivity_banner_host.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

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
  _FakeRepo(this.items);

  final List<NotificationItem> items;

  @override
  Future<Either<Failure, NotificationsPage>> getNotifications({
    required int page,
    required int pageSize,
  }) async => Right(
    NotificationsPage(items: page == 1 ? items : const [], hasMore: false),
  );
}

class _FakeGetBadges extends Fake implements GetBadgesUseCase {}

class _FakeMarkTabSeen extends Fake implements MarkTabSeenUseCase {}

/// Records which tabs the screen marked seen, without touching the network.
class SpyBadgesCubit extends BadgesCubit {
  SpyBadgesCubit()
    : super(getBadges: _FakeGetBadges(), markTabSeen: _FakeMarkTabSeen());

  final List<String> seenTabs = [];

  @override
  Future<void> markSeen(String tabKey) async => seenTabs.add(tabKey);
}

/// The inbox's badge spy, from the last [pumpInbox].
late SpyBadgesCubit inboxBadges;

/// The inbox over three unread rows, or [items]. With [offline] set, under
/// the banner host too; [wrap] puts more above the navigator, and [home]
/// stands in for the inbox as the first screen.
Future<void> pumpInbox(
  WidgetTester tester, {
  bool? offline,
  List<NotificationItem>? items,
  Widget Function(Widget navigator)? wrap,
  Widget home = const NotificationsScreen(),
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = SharedPrefService(await SharedPreferences.getInstance());
  final usecase = GetNotificationsUseCase(
    _FakeRepo(items ?? [_item(3), _item(2), _item(1)]),
  );

  inboxBadges = SpyBadgesCubit();
  sl.registerFactory<NotificationsCubit>(
    () => NotificationsCubit(getNotifications: usecase),
  );
  sl.registerLazySingleton<NotificationReadCubit>(
    () => NotificationReadCubit(prefs: prefs),
  );
  sl.registerLazySingleton<BadgesCubit>(() => inboxBadges);

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
          builder: (_, child) {
            final navigator = offline == null
                ? child!
                : ConnectivityBannerHost(offline: offline, child: child!);
            return wrap == null ? navigator : wrap(navigator);
          },
          home: home,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
