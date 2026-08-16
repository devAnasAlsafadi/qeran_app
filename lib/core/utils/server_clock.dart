import 'dart:async';

import 'package:flutter/foundation.dart';

import '../constants/storage_keys.dart';
import '../services/storage_service.dart';

/// The server's clock, as best this device can estimate it.
///
/// Every deadline the backend sends (`expiresAt`) is a point on the SERVER's
/// timeline, but "has it passed?" is asked on the device's. A phone that flew
/// two timezones, sat in a drawer for a week, or was restored from a backup
/// answers that question wrongly — showing a live countdown on a dead request,
/// or hiding one that is still open.
///
/// The fix is not to trust the device's absolute time. Where a response carries
/// BOTH a deadline and the server's own `remainingSeconds` snapshot, the two
/// pin down the server's clock exactly:
///
///     serverNow = expiresAt - remainingSeconds
///     skew      = serverNow - deviceNow
///
/// [now] then adds that offset. Elapsed time is still measured on the device,
/// which is correct — clocks drift in their zero point, not in their rate.
///
/// Persisted across launches so a cold start is not defenceless: the stored
/// value is only ever a fallback, replaced by the first fresh response that can
/// recalibrate. See [restore].
class ServerClock {
  ServerClock._();

  /// Process-wide instance. Swappable in tests via [resetForTest].
  static ServerClock instance = ServerClock._();

  /// Below this, a re-calibration is not written to disk — successive
  /// responses disagree by a second or two from rounding alone, and that is
  /// not worth a write per list refresh.
  static const Duration _persistThreshold = Duration(seconds: 5);

  StorageService? _storage;
  Duration _skew = Duration.zero;

  /// The current offset (server − device). Zero until first calibrated.
  Duration get skew => _skew;

  /// Adopts the last persisted offset. Call once during bootstrap, BEFORE the
  /// first screen can render a countdown — the stored value is what protects
  /// the first paint of a cold start, when no response has landed yet.
  Future<void> restore(StorageService storage) async {
    _storage = storage;
    final millis = await storage.get<int>(StorageKeys.serverClockSkewMs);
    if (millis != null) _skew = Duration(milliseconds: millis);
  }

  /// Re-derives the offset from a response that carries both halves of the
  /// pair. No-ops when either is missing (nothing to solve) or when
  /// `remainingSeconds` is negative — the newer backend reports elapsed
  /// deadlines rather than nulling them, and a past deadline says nothing
  /// about the clock.
  void calibrate({DateTime? expiresAt, int? remainingSeconds}) {
    if (expiresAt == null || remainingSeconds == null) return;
    if (remainingSeconds < 0) return;
    final serverNow = expiresAt.toUtc().subtract(
      Duration(seconds: remainingSeconds),
    );
    final observed = serverNow.difference(DateTime.now().toUtc());
    final moved = (observed - _skew).abs();
    _skew = observed;
    if (moved < _persistThreshold) return;
    unawaited(
      _storage?.save(StorageKeys.serverClockSkewMs, observed.inMilliseconds),
    );
  }

  /// Calibrates from the first usable pair in [samples] — list endpoints hand
  /// back many rows and they all agree, so one is enough.
  void calibrateFromAny(
    Iterable<({DateTime? expiresAt, int? remainingSeconds})> samples,
  ) {
    for (final s in samples) {
      if (s.expiresAt == null || (s.remainingSeconds ?? -1) < 0) continue;
      calibrate(expiresAt: s.expiresAt, remainingSeconds: s.remainingSeconds);
      return;
    }
  }

  /// Now, on the server's timeline.
  DateTime now() => DateTime.now().toUtc().add(_skew);

  /// Whether [expiresAt] is in the past.
  ///
  /// A null deadline is NOT an expiry. The backend used to null the field to
  /// mean "expired" and now sends the real timestamp instead; during the
  /// rollout an absent value means only that this payload never carried one,
  /// and reading it as expired would blank live countdowns.
  bool hasExpired(DateTime? expiresAt) =>
      expiresAt != null && !now().isBefore(expiresAt.toUtc());

  @visibleForTesting
  static void resetForTest() => instance = ServerClock._();

  @visibleForTesting
  void setSkewForTest(Duration value) => _skew = value;
}

/// Whether [expiresAt] has passed on the server's clock — the app-wide answer
/// to "is this deadline still open?". Prefer this over `DateTime.now()`
/// comparisons anywhere a server deadline is involved.
bool hasServerExpired(DateTime? expiresAt) =>
    ServerClock.instance.hasExpired(expiresAt);
