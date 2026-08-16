import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/core/utils/server_clock.dart';

/// The point of [ServerClock] is that the answer to "has this deadline passed?"
/// must NOT change when the device's clock does. These tests therefore always
/// assert on a case where a skewed device would answer differently.

class _FakeStorage implements StorageService {
  final Map<String, Object?> values = {};

  @override
  Future<T?> get<T>(String key) async => values[key] as T?;

  @override
  Future<void> save<T>(String key, T value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);

  @override
  Future<void> clear() async => values.clear();
}

/// Duration equality with slack — the calibration reads the wall clock twice.
Matcher _about(Duration expected) => predicate<Duration>(
  (d) => (d - expected).abs() < const Duration(seconds: 2),
  'within 2s of $expected',
);

void main() {
  setUp(ServerClock.resetForTest);

  group('calibration', () {
    test('solves the offset from a deadline plus the server snapshot', () {
      final deviceNow = DateTime.now().toUtc();
      // The server says 10 minutes remain, but by THIS device's clock the
      // deadline is 70 minutes out — so the device is an hour behind.
      ServerClock.instance.calibrate(
        expiresAt: deviceNow.add(const Duration(hours: 1, minutes: 10)),
        remainingSeconds: 600,
      );

      expect(ServerClock.instance.skew, _about(const Duration(hours: 1)));
    });

    test('the offset changes the verdict, which is the whole point', () {
      final deviceNow = DateTime.now().toUtc();
      ServerClock.instance.calibrate(
        expiresAt: deviceNow.add(const Duration(hours: 1, minutes: 10)),
        remainingSeconds: 600,
      );

      // Half an hour ahead on the device's clock — but the server is an hour
      // further on, so it has already lapsed. A naive DateTime.now() check
      // would call this live and show a running countdown on a dead request.
      expect(
        ServerClock.instance.hasExpired(
          deviceNow.add(const Duration(minutes: 30)),
        ),
        isTrue,
      );
      expect(
        ServerClock.instance.hasExpired(
          deviceNow.add(const Duration(hours: 2)),
        ),
        isFalse,
      );
    });

    test('a lapsed row teaches nothing — negative snapshots are ignored', () {
      ServerClock.instance.setSkewForTest(const Duration(minutes: 5));
      ServerClock.instance.calibrate(
        expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 3)),
        remainingSeconds: -9000,
      );

      expect(ServerClock.instance.skew, const Duration(minutes: 5));
    });

    test('a half-pair teaches nothing either', () {
      ServerClock.instance.setSkewForTest(const Duration(minutes: 5));
      ServerClock.instance.calibrate(expiresAt: DateTime.now().toUtc());
      ServerClock.instance.calibrate(remainingSeconds: 600);

      expect(ServerClock.instance.skew, const Duration(minutes: 5));
    });

    test('calibrateFromAny takes the first row that can actually solve', () {
      final deviceNow = DateTime.now().toUtc();
      ServerClock.instance.calibrateFromAny([
        (expiresAt: null, remainingSeconds: 600), // no deadline
        (expiresAt: deviceNow, remainingSeconds: null), // no snapshot
        (
          expiresAt: deviceNow.add(const Duration(minutes: 40)),
          remainingSeconds: 600,
        ), // usable: device is 30 min behind
      ]);

      expect(ServerClock.instance.skew, _about(const Duration(minutes: 30)));
    });
  });

  group('a null deadline is not an expiry', () {
    test('hasExpired(null) is false', () {
      // The backend USED to null this field to mean "expired". Reading it that
      // way now would blank every live countdown on a payload that predates
      // the change.
      expect(ServerClock.instance.hasExpired(null), isFalse);
      expect(hasServerExpired(null), isFalse);
    });
  });

  group('persistence across launches', () {
    test('restore adopts the stored offset for the cold start', () async {
      final storage = _FakeStorage();
      storage.values[StorageKeys.serverClockSkewMs] = 90 * 1000;

      await ServerClock.instance.restore(storage);

      expect(ServerClock.instance.skew, const Duration(seconds: 90));
    });

    test('nothing stored leaves the clock untouched', () async {
      await ServerClock.instance.restore(_FakeStorage());

      expect(ServerClock.instance.skew, Duration.zero);
    });

    test('a meaningful move is written back', () async {
      final storage = _FakeStorage();
      await ServerClock.instance.restore(storage);

      ServerClock.instance.calibrate(
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 40)),
        remainingSeconds: 600,
      );
      await Future<void>.delayed(Duration.zero); // the write is fire-and-forget

      final stored = storage.values[StorageKeys.serverClockSkewMs] as int?;
      expect(stored, isNotNull);
      expect(
        Duration(milliseconds: stored!),
        _about(const Duration(minutes: 30)),
      );
    });

    test('rounding jitter does not cause a write per refresh', () async {
      final storage = _FakeStorage();
      await ServerClock.instance.restore(storage);

      // Two responses one second apart in their view of the deadline: the
      // in-memory value must track, the disk must not churn.
      ServerClock.instance.calibrate(
        expiresAt: DateTime.now().toUtc().add(const Duration(seconds: 601)),
        remainingSeconds: 600,
      );
      await Future<void>.delayed(Duration.zero);
      storage.values.clear();

      ServerClock.instance.calibrate(
        expiresAt: DateTime.now().toUtc().add(const Duration(seconds: 602)),
        remainingSeconds: 600,
      );
      await Future<void>.delayed(Duration.zero);

      expect(storage.values, isEmpty);
      expect(ServerClock.instance.skew, _about(const Duration(seconds: 2)));
    });
  });
}
