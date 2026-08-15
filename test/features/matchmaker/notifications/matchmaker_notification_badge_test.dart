import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/matchmaker/notifications/domain/entities/matchmaker_notification.dart';
import 'package:qeran/features/matchmaker/notifications/domain/entities/matchmaker_notifications_page.dart';
import 'package:qeran/features/matchmaker/notifications/domain/repositories/matchmaker_notifications_repository.dart';
import 'package:qeran/features/matchmaker/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:qeran/features/matchmaker/notifications/presentation/blocs/matchmaker_notification_badge_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The matchmaker bell keys off the newest notification ID, like the user app's
/// `NotificationBadgeCubit`. It used to key off the TOTAL COUNT, and the
/// swallow that caused is the case that matters most here.

MatchmakerNotification _item(int id) => MatchmakerNotification(
  id: id,
  titleAr: 'عنوان $id',
  titleEn: 'Title $id',
  bodyAr: 'نص',
  bodyEn: 'Body',
  type: MatchmakerNotificationType.general,
  data: const {},
  createdAt: null,
);

/// Newest-first, like the endpoint. [newestId] is mutable so a test can let the
/// server move on between fetches.
class _FakeRepo extends Fake implements MatchmakerNotificationsRepository {
  _FakeRepo({this.newestId = 0});

  int newestId;
  bool fails = false;
  int calls = 0;

  @override
  Future<Either<Failure, MatchmakerNotificationsPage>> getNotifications({
    required int page,
    required int pageSize,
  }) async {
    calls++;
    if (fails) return const Left(ServerFailure(message: 'offline'));
    return Right(
      MatchmakerNotificationsPage(
        items: newestId == 0 ? const [] : [_item(newestId)],
        hasMore: false,
      ),
    );
  }
}

Future<SharedPrefService> _prefs([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return SharedPrefService(await SharedPreferences.getInstance());
}

MatchmakerNotificationBadgeCubit _cubit(
  _FakeRepo repo,
  SharedPrefService prefs,
) => MatchmakerNotificationBadgeCubit(
  getNotifications: GetNotificationsUseCase(repo),
  prefs: prefs,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a fresh install with notifications waiting lights the bell', () async {
    final cubit = _cubit(_FakeRepo(newestId: 9), await _prefs());
    await cubit.refresh();

    expect(cubit.state, isTrue);
  });

  test('opening the inbox clears it and stores the newest id', () async {
    final prefs = await _prefs();
    final cubit = _cubit(_FakeRepo(newestId: 9), prefs);
    await cubit.refresh();

    await cubit.markAllSeen();

    expect(cubit.state, isFalse);
    expect(await prefs.get<int>(StorageKeys.matchmakerNotifLastSeenId), 9);

    // And it stays clear while nothing newer arrives.
    await cubit.refresh();
    expect(cubit.state, isFalse);
  });

  // THE regression. Under the old count heuristic the baseline was a TOTAL:
  // seen 3 of 3. Delete one server-side (2) and let one arrive (3) and the
  // arithmetic gives max(0, 3 - 3) = 0 — the bell stays dark and a real
  // notification is swallowed. An id only ever goes up, so it cannot happen.
  test('a deleted notification cannot swallow the next arrival', () async {
    final repo = _FakeRepo(newestId: 9);
    final prefs = await _prefs();
    final cubit = _cubit(repo, prefs);

    await cubit.markAllSeen();
    expect(cubit.state, isFalse);

    // One older row is deleted server-side and one new row arrives: the TOTAL
    // is unchanged, the newest id is not.
    repo.newestId = 10;
    await cubit.refresh();

    expect(cubit.state, isTrue);
  });

  test('an empty inbox leaves the bell dark', () async {
    final cubit = _cubit(_FakeRepo(), await _prefs());
    await cubit.refresh();

    expect(cubit.state, isFalse);
  });

  test('a transient failure never flips the badge', () async {
    final repo = _FakeRepo(newestId: 9);
    final cubit = _cubit(repo, await _prefs());
    await cubit.refresh();
    expect(cubit.state, isTrue);

    repo.fails = true;
    await cubit.refresh();

    expect(cubit.state, isTrue, reason: 'keeps its last value');
  });

  test('the two roles never share a last-seen key', () async {
    final prefs = await _prefs({StorageKeys.notifLastSeenId: 99});
    final cubit = _cubit(_FakeRepo(newestId: 9), prefs);

    await cubit.refresh();
    // Unread despite the USER key being far ahead — it is not read from.
    expect(cubit.state, isTrue);

    await cubit.markAllSeen();
    expect(await prefs.get<int>(StorageKeys.notifLastSeenId), 99);
  });

  test('back-to-back refresh and open share one request', () async {
    final repo = _FakeRepo(newestId: 9);
    final cubit = _cubit(repo, await _prefs());

    await Future.wait([cubit.refresh(), cubit.markAllSeen()]);

    expect(repo.calls, 1);
  });
}
