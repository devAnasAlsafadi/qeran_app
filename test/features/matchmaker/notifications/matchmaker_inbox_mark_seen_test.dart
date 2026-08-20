import 'package:dartz/dartz.dart';
// easy_localization re-exports intl, whose TextDirection collides with
// dart:ui's — the one Directionality actually takes.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/connectivity/connectivity_cubit.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/services/connectivity_service.dart';
import 'package:qeran/features/badges/domain/entities/badge_tab_keys.dart';
import 'package:qeran/features/badges/domain/usecases/get_badges_usecase.dart';
import 'package:qeran/features/badges/domain/usecases/mark_tab_seen_usecase.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/features/matchmaker/notifications/domain/entities/matchmaker_notification.dart';
import 'package:qeran/features/matchmaker/notifications/domain/entities/matchmaker_notifications_page.dart';
import 'package:qeran/features/matchmaker/notifications/domain/repositories/matchmaker_notifications_repository.dart';
import 'package:qeran/features/matchmaker/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:qeran/features/matchmaker/notifications/presentation/blocs/matchmaker_notification_read_cubit.dart';
import 'package:qeran/features/matchmaker/notifications/presentation/blocs/matchmaker_notifications_cubit.dart';
import 'package:qeran/features/matchmaker/notifications/presentation/screens/matchmaker_notifications_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The bell's unread count is the server's now, so "seen" is a POST rather than
/// a stored id. Two rules survived that migration, and both live in the inbox's
/// dispose:
/// * marked on the way OUT, so the badge outlives the visit it belongs to;
/// * only if the list actually loaded — clearing is server-side and one-way, so
///   a failed load must not spend it.
///
/// The matchmaker used to mark seen in `initState`. That is what the guard cost
/// it, and why the two roles now agree.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

const _row = MatchmakerNotification(
  id: 7,
  titleAr: 'تحديث',
  titleEn: 'Update',
  bodyAr: 'نص',
  bodyEn: 'Body',
  type: MatchmakerNotificationType.general,
  data: <String, dynamic>{},
  createdAt: null,
);

/// The failure path renders [QeranErrorState], which reads connectivity to
/// decide between "offline" and "something went wrong".
class _FakeConnectivity extends Fake implements ConnectivityService {
  @override
  Future<bool> get isOnline async => true;

  @override
  Stream<bool> get onStatusChange => const Stream<bool>.empty();
}

class _FakeGetBadges extends Fake implements GetBadgesUseCase {}

class _FakeMarkTabSeen extends Fake implements MarkTabSeenUseCase {}

/// Records which tabs were marked seen, without touching the network.
class _SpyBadgesCubit extends BadgesCubit {
  _SpyBadgesCubit()
    : super(getBadges: _FakeGetBadges(), markTabSeen: _FakeMarkTabSeen());

  final List<String> seenTabs = [];

  @override
  Future<void> markSeen(String tabKey) async => seenTabs.add(tabKey);
}

class _FakeRepo extends Fake implements MatchmakerNotificationsRepository {
  _FakeRepo({this.fails = false});

  final bool fails;

  @override
  Future<Either<Failure, MatchmakerNotificationsPage>> getNotifications({
    required int page,
    required int pageSize,
  }) async {
    if (fails) return const Left(ServerFailure(message: 'network'));
    return Right(
      MatchmakerNotificationsPage(
        items: page == 1 ? const [_row] : const [],
        hasMore: false,
      ),
    );
  }
}

late _SpyBadgesCubit _badges;

Future<void> _pumpInbox(WidgetTester tester, {bool fails = false}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = SharedPrefService(await SharedPreferences.getInstance());
  final repo = _FakeRepo(fails: fails);

  _badges = _SpyBadgesCubit();
  sl.registerFactory(
    () => MatchmakerNotificationsCubit(
      getNotifications: GetNotificationsUseCase(repo),
    ),
  );
  sl.registerFactory(() => MatchmakerNotificationReadCubit(prefs: prefs));
  sl.registerLazySingleton<BadgesCubit>(() => _badges);

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
          home: BlocProvider<ConnectivityCubit>(
            create: (_) => ConnectivityCubit(service: _FakeConnectivity()),
            child: const MatchmakerNotificationsScreen(),
          ),
        ),
      ),
    ),
  );
  // EasyLocalization resolves its delegates asynchronously; the tree below it
  // does not exist on the first frame.
  await tester.pumpAndSettle();
}

Future<void> _leave(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  // `sl.reset()` is async — awaiting it matters, or the reset lands AFTER the
  // registrations above and wipes them.
  setUp(() async => sl.reset());

  testWidgets('the bell is marked seen on the way OUT, not on load', (
    tester,
  ) async {
    await _pumpInbox(tester);

    // Still on the screen: the badge must survive the visit it belongs to.
    expect(_badges.seenTabs, isEmpty);

    await _leave(tester);

    expect(_badges.seenTabs, [BadgeTabKeys.notifications]);
  });

  // The guard is why this moved out of initState. Spend the clear on a load
  // that failed and the badge is gone for notifications nobody ever saw —
  // there is no local id left to rebuild it from.
  testWidgets('a failed load marks nothing seen', (tester) async {
    await _pumpInbox(tester, fails: true);
    await _leave(tester);

    expect(_badges.seenTabs, isEmpty);
  });
}
