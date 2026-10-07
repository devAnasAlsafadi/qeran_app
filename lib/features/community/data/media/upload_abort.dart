import 'dart:async';

import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// One upload's way to stop: her cancel, or nothing moving for the stall
/// time. Once it fired, it explains whatever the client threw. The same as
/// `HttpProgressUploader`'s, which is private to its file (one copy should
/// move to `core/api` when that file is next touched), except that a cancel
/// made before the upload started has already fired: `whenCancelled` would
/// only say so after the first request went out.
class UploadAbort {
  UploadAbort(UploadCancel? cancel, this._stall) {
    if (cancel?.isCancelled ?? false) _fire(cancelled: true);
    cancel?.whenCancelled.then((_) => _fire(cancelled: true));
    alive();
  }

  final Duration _stall;
  final _trigger = Completer<void>();
  Timer? _timer;
  bool _cancelled = false;

  /// Each request's `abortTrigger`.
  Future<void> get trigger => _trigger.future;

  /// Something moved: the stall clock starts again.
  void alive() {
    if (_trigger.isCompleted) return;
    _timer?.cancel();
    _timer = Timer(_stall, () => _fire(cancelled: false));
  }

  void _fire({required bool cancelled}) {
    if (_trigger.isCompleted) return;
    _cancelled = cancelled;
    _timer?.cancel();
    _trigger.complete();
  }

  /// Her cancel, or a stall's timeout; null while it hasn't fired.
  Exception? explain() {
    if (!_trigger.isCompleted) return null;
    return _cancelled
        ? const UploadCancelledException()
        : ServerException(message: LocaleKeys.errors_timeout);
  }

  /// Between two requests: one that fired stops here, before the next is
  /// sent at all.
  void throwIfFired() {
    final stop = explain();
    if (stop != null) throw stop;
  }

  void dispose() => _timer?.cancel();
}
