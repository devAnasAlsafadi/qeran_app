import 'dart:async';

/// Single-shot debouncer. Each [run] call cancels any previous pending
/// callback and schedules a new one [delay] in the future. Designed for
/// search-input streams where only the latest keystroke should hit the
/// API after the user stops typing.
///
/// Always call [dispose] from the owning controller / cubit so a fired
/// timer cannot outlive the screen.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 350)});

  final Duration delay;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
