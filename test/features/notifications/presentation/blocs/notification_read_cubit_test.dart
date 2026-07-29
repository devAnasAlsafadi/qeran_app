import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/features/notifications/presentation/blocs/notification_read_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local read-state for the inbox — the backend exposes none.
///
/// Two parts on purpose: a watermark ("everything this old is read") plus the
/// few ids above it opened one at a time. The pairing is what keeps the stored
/// list from growing forever, so most of what matters here is that the two stay
/// consistent with each other.

Future<NotificationReadCubit> _cubit([Map<String, Object> seed = const {}]) async {
  SharedPreferences.setMockInitialValues(seed);
  final prefs = SharedPrefService(await SharedPreferences.getInstance());
  return NotificationReadCubit(prefs: prefs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('everything is unread before anything is stored', () async {
    final cubit = await _cubit();
    await cubit.load();

    expect(cubit.state.isUnread(1), isTrue);
    expect(cubit.state.isUnread(9999), isTrue);
  });

  test('marking one read leaves the others alone', () async {
    final cubit = await _cubit();
    await cubit.load();

    await cubit.markRead(42);

    expect(cubit.state.isRead(42), isTrue);
    expect(cubit.state.isUnread(43), isTrue);
    expect(cubit.state.isUnread(41), isTrue);
  });

  test('mark-all reads everything up to the newest id', () async {
    final cubit = await _cubit();
    await cubit.load();

    await cubit.markAllRead(100);

    expect(cubit.state.isRead(100), isTrue);
    expect(cubit.state.isRead(1), isTrue);
    // Anything the server sends AFTER the sweep is still new.
    expect(cubit.state.isUnread(101), isTrue);
  });

  test('mark-all drops the per-id list it just made redundant', () async {
    final cubit = await _cubit();
    await cubit.load();
    await cubit.markRead(7);

    await cubit.markAllRead(100);

    expect(cubit.state.readIds, isEmpty);
    expect(cubit.state.isRead(7), isTrue);
  });

  test('a late older page can never un-read anything', () async {
    final cubit = await _cubit();
    await cubit.load();
    await cubit.markAllRead(100);

    await cubit.markAllRead(30);

    expect(cubit.state.watermark, 100);
    expect(cubit.state.isRead(90), isTrue);
  });

  test('state survives a restart', () async {
    final first = await _cubit();
    await first.load();
    await first.markAllRead(50);
    await first.markRead(77);

    // Same prefs, fresh cubit — as if the app were relaunched.
    final prefs = SharedPrefService(await SharedPreferences.getInstance());
    final second = NotificationReadCubit(prefs: prefs);
    await second.load();

    expect(second.state.isRead(50), isTrue);
    expect(second.state.isRead(77), isTrue);
    expect(second.state.isUnread(78), isTrue);
  });

  test('load prunes stored ids the watermark already covers', () async {
    final cubit = await _cubit({
      StorageKeys.notifReadWatermark: 100,
      StorageKeys.notifReadIds: <String>['7', '42', '140'],
    });

    await cubit.load();

    // 7 and 42 are below the watermark — read either way, and no reason to
    // keep carrying them.
    expect(cubit.state.readIds, {140});
    expect(cubit.state.isRead(42), isTrue);
  });

  test('hasUnreadAmong drives whether the sweep is worth offering', () async {
    final cubit = await _cubit();
    await cubit.load();

    expect(cubit.state.hasUnreadAmong([1, 2, 3]), isTrue);
    await cubit.markAllRead(3);
    expect(cubit.state.hasUnreadAmong([1, 2, 3]), isFalse);
    expect(cubit.state.hasUnreadAmong([1, 2, 3, 4]), isTrue);
  });
}
