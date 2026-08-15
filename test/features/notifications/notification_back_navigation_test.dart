import 'package:dartz/dartz.dart';
// easy_localization re-exports intl, whose TextDirection collides with
// dart:ui's — the one Directionality actually takes.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/design_system/widgets/qeran_app_bar.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/home/presentation/home_shell_scope.dart';
import 'package:qeran/features/matchmaker/home/presentation/home_shell_scope.dart';
import 'package:qeran/features/matchmaker/notifications/domain/entities/matchmaker_notification.dart';
import 'package:qeran/features/matchmaker/notifications/domain/entities/matchmaker_notifications_page.dart';
import 'package:qeran/features/matchmaker/notifications/domain/repositories/matchmaker_notifications_repository.dart';
import 'package:qeran/features/matchmaker/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:qeran/features/matchmaker/notifications/presentation/blocs/matchmaker_notification_badge_cubit.dart';
import 'package:qeran/features/matchmaker/notifications/presentation/blocs/matchmaker_notification_read_cubit.dart';
import 'package:qeran/features/matchmaker/notifications/presentation/blocs/matchmaker_notifications_cubit.dart';
import 'package:qeran/features/matchmaker/notifications/presentation/screens/matchmaker_notifications_screen.dart';
import 'package:qeran/features/matchmaker/shared/data/matchmaker_notification_router.dart';
import 'package:qeran/features/notifications/presentation/widgets/notification_back_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Client rule: every notification target must offer a way back to the inbox,
/// whether it is a pushed route or a bottom tab.
///
/// A tab cannot pop to the inbox — the inbox pops ITSELF on the way to a tab,
/// and never exists at all when the push was tapped from outside the app. So
/// the control is driven by a shell flag and reopens the inbox by pushing it.
/// These pin the four pieces that makes rest on.

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

MatchmakerNotification _caseRow() => const MatchmakerNotification(
  id: 7,
  titleAr: 'تحديث حالة',
  titleEn: 'Case update',
  bodyAr: 'نص',
  bodyEn: 'Body',
  type: MatchmakerNotificationType.general,
  // The exact shape MatchmakerNotificationRouter demands for a Cases link:
  // the same event is pushed to the two USERS too, so `audience` is what keeps
  // the matchmaker shell from acting on a user-targeted push.
  data: {'action': 'compatibility_case_updated', 'audience': 'matchmaker'},
  createdAt: null,
);

class _FakeRepo extends Fake implements MatchmakerNotificationsRepository {
  @override
  Future<Either<Failure, MatchmakerNotificationsPage>> getNotifications({
    required int page,
    required int pageSize,
  }) async => Right(
    MatchmakerNotificationsPage(
      items: page == 1 ? [_caseRow()] : const [],
      hasMore: false,
    ),
  );

  @override
  Future<Either<Failure, int>> getCount() async => const Right(0);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() async => sl.reset());

  group('the seam a tab hangs its back control on', () {
    // QeranAppBar draws no leading on a tab because canPop() is false there —
    // which is exactly why the tabs had no back arrow. onBack overrides that,
    // and it is how the matchmaker tabs get theirs.
    testWidgets('an app bar with onBack draws a leading with nothing to pop', (
      tester,
    ) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: QeranAppBar(title: 'Cases', onBack: () => tapped++),
          ),
        ),
      );

      expect(find.byType(QeranBackButton), findsOneWidget);
      await tester.tap(find.byType(QeranBackButton));
      expect(tapped, 1);
    });

    testWidgets('...and none without it, on that same root route', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(appBar: QeranAppBar(title: 'Cases')),
        ),
      );

      expect(find.byType(QeranBackButton), findsNothing);
    });

    // The user tabs have no app bar at all, so they carry the same glyph
    // through this row instead.
    testWidgets('the user-tab row carries the same glyph', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: NotificationBackRow(onBack: () => tapped++)),
        ),
      );

      expect(find.byType(QeranBackButton), findsOneWidget);
      await tester.tap(find.byType(QeranBackButton));
      expect(tapped, 1);
    });
  });

  group('the flag reaches the tabs', () {
    // Both scopes returned a flat false, correct while every field was a stable
    // callback. A tab would never have rebuilt when the flag flipped.
    test('the user scope notifies on the flag, and only on it', () {
      HomeShellScope scope({required bool from}) => HomeShellScope(
        openLikesTab: () {},
        openMessagesTab: ({bool refresh = false}) {},
        openProfileTab: () {},
        openFromNotification: (_) {},
        fromNotification: from,
        returnToNotifications: () {},
        child: const SizedBox.shrink(),
      );

      expect(scope(from: true).updateShouldNotify(scope(from: false)), isTrue);
      expect(scope(from: true).updateShouldNotify(scope(from: true)), isFalse);
    });

    test('the matchmaker scope behaves identically', () {
      MatchmakerHomeShellScope scope({required bool from}) =>
          MatchmakerHomeShellScope(
            openTab: (_, {usersSubTab}) {},
            openFromNotification: (_) {},
            fromNotification: from,
            returnToNotifications: () {},
            child: const SizedBox.shrink(),
          );

      expect(scope(from: true).updateShouldNotify(scope(from: false)), isTrue);
      expect(scope(from: true).updateShouldNotify(scope(from: true)), isFalse);
    });

    testWidgets('a tab picks up the flip without being rebuilt by its parent', (
      tester,
    ) async {
      Widget host(bool from) => MaterialApp(
        home: HomeShellScope(
          openLikesTab: () {},
          openMessagesTab: ({bool refresh = false}) {},
          openProfileTab: () {},
          openFromNotification: (_) {},
          fromNotification: from,
          returnToNotifications: () {},
          child: Builder(
            builder: (context) {
              final shell = HomeShellScope.maybeOf(context);
              return (shell?.fromNotification ?? false)
                  ? NotificationBackRow(onBack: shell!.returnToNotifications)
                  : const SizedBox.shrink();
            },
          ),
        ),
      );

      await tester.pumpWidget(host(false));
      expect(find.byType(QeranBackButton), findsNothing);

      await tester.pumpWidget(host(true));
      expect(find.byType(QeranBackButton), findsOneWidget);
    });
  });

  // The destination itself, not just the arrow: this row used to hit a bare
  // `break`, so tapping a case notification in the matchmaker inbox did
  // nothing whatsoever.
  testWidgets('a case row hands its intent back to the shell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = SharedPrefService(await SharedPreferences.getInstance());
    final repo = _FakeRepo();

    sl.registerFactory(
      () => MatchmakerNotificationsCubit(
        getNotifications: GetNotificationsUseCase(repo),
      ),
    );
    sl.registerFactory(() => MatchmakerNotificationReadCubit(prefs: prefs));
    sl.registerLazySingleton(
      () => MatchmakerNotificationBadgeCubit(
        getNotifications: GetNotificationsUseCase(repo),
        prefs: prefs,
      ),
    );

    Object? popped;
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
            home: Builder(
              builder: (routeContext) => ElevatedButton(
                onPressed: () async {
                  popped = await Navigator.of(routeContext).push<Object?>(
                    MaterialPageRoute<Object?>(
                      builder: (_) => const MatchmakerNotificationsScreen(),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    // EasyLocalization resolves its delegates asynchronously; the tree below it
    // does not exist on the first frame.
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Case update'), findsOneWidget);

    await tester.tap(find.text('Case update'));
    await tester.pumpAndSettle();

    // Popped WITH the intent — the shell below applies it and raises the flag.
    expect(popped, isA<OpenCases>());
  });
}
