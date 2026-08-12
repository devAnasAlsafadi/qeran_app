import 'dart:math' as math;

/// Process-local monotonic clocks for active reveal windows.
///
/// A gallery route may close and reopen during the same 60-second window. The
/// permission endpoint intentionally does not require `secondsRemaining`, so a
/// singleton clock preserves the server-provided POST value across scoped
/// cubit instances without consulting the device wall clock.
class PhotoViewSessionClock {
  final Map<int, _WindowClock> _windows = {};

  void start(int photoExchangeId, int secondsRemaining) {
    _windows.putIfAbsent(photoExchangeId, () => _WindowClock(secondsRemaining));
  }

  int remaining(int photoExchangeId) {
    final window = _windows[photoExchangeId];
    if (window == null) return 0;
    final remaining = math.max(
      0,
      window.seconds - (window.stopwatch.elapsedMilliseconds ~/ 1000),
    );
    if (remaining == 0) _windows.remove(photoExchangeId);
    return remaining;
  }

  void remove(int photoExchangeId) => _windows.remove(photoExchangeId);
}

class _WindowClock {
  final int seconds;
  final Stopwatch stopwatch = Stopwatch()..start();

  _WindowClock(this.seconds);
}
