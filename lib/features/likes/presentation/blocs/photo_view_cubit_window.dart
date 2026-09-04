part of 'photo_view_cubit.dart';

/// What a permission MEANS, and the countdown it drives.
///
/// Split from the cubit for size, along the one seam that leaves the access
/// guard intact: everything that decides whether a write is allowed to land —
/// the authority version, where it is stamped, where it is compared and both
/// places it is bumped — stays together in the cubit itself. This half only
/// acts on a permission that has already been accepted as current, and owns
/// the ticker and the session clock that follow from it.
extension PhotoViewWindow on PhotoViewCubit {
  void _applyPermission(PhotoViewPermission permission) {
    final exchangeId = permission.photoExchangeId;
    if (exchangeId == null) {
      _stopWindow();
      emit(
        PhotoViewState(
          phase: PhotoViewPhase.unavailable,
          permission: permission,
        ),
      );
      return;
    }
    if (permission.isConsumed) {
      _sessionClock.remove(exchangeId);
      _stopWindow();
      emit(
        PhotoViewState(phase: PhotoViewPhase.consumed, permission: permission),
      );
      return;
    }
    if (permission.viewedAt == null) {
      _sessionClock.remove(exchangeId);
      _stopWindow();
      emit(
        PhotoViewState(phase: PhotoViewPhase.available, permission: permission),
      );
      return;
    }
    if (permission.isUnblurred) {
      final existingRemaining = _sessionClock.remaining(exchangeId);
      if (existingRemaining > 0) {
        _activeExchangeId = exchangeId;
        _startTicker();
        _emitViewing(permission, existingRemaining);
        return;
      }
      final serverRemaining = permission.secondsRemaining ?? 0;
      if (serverRemaining > 0) {
        _startClock(exchangeId, serverRemaining);
        _emitViewing(permission, serverRemaining);
        return;
      }
      // Never derive this from viewExpiresAt vs the device wall clock. If the
      // server did not provide seconds after a process restart, fail closed.
      _stopWindow();
      emit(
        PhotoViewState(
          phase: PhotoViewPhase.failure,
          permission: permission,
          errorMessage: LocaleKeys.errors_invalid_server_response,
        ),
      );
      return;
    }

    _sessionClock.remove(exchangeId);
    _stopWindow();
    emit(
      PhotoViewState(phase: PhotoViewPhase.consumed, permission: permission),
    );
  }

  void _startSession(PhotoViewSession session) {
    final remaining = session.secondsRemaining < 0
        ? 0
        : session.secondsRemaining;
    if (remaining == 0) {
      markImageAccessConsumed();
      return;
    }
    _startClock(session.photoExchangeId, remaining);
    _emitViewing(state.permission, remaining);
  }

  void _startClock(int exchangeId, int seconds) {
    _sessionClock.start(exchangeId, seconds);
    _activeExchangeId = exchangeId;
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _onTick(),
    );
  }

  void _onTick() {
    if (isClosed) return;
    final remaining = _remainingSeconds;
    if (remaining <= 0) {
      markImageAccessConsumed();
      return;
    }
    if (state.phase == PhotoViewPhase.viewing &&
        state.secondsRemaining != remaining) {
      emit(state.copyWith(secondsRemaining: remaining));
    }
  }

  int get _remainingSeconds {
    final exchangeId = _activeExchangeId;
    return exchangeId == null ? 0 : _sessionClock.remaining(exchangeId);
  }

  void _emitViewing(PhotoViewPermission? permission, int seconds) {
    emit(
      PhotoViewState(
        phase: PhotoViewPhase.viewing,
        permission: permission,
        secondsRemaining: seconds,
      ),
    );
  }

  Future<void> _refreshAfterLock() async {
    final result = await _getPermission(targetUserId);
    if (isClosed) return;
    result.fold((_) {}, (permission) {
      if (permission.isConsumed || !permission.isUnblurred) {
        emit(
          PhotoViewState(
            phase: PhotoViewPhase.consumed,
            permission: permission,
            // This reconciliation follows an event that has already been
            // delivered; carrying the counter forward keeps it monotonic so a
            // later expiry still registers as new.
            eventVersion: state.eventVersion,
          ),
        );
      }
    });
  }

  void _stopWindow() {
    _ticker?.cancel();
    _ticker = null;
    final exchangeId = _activeExchangeId;
    if (exchangeId != null) _sessionClock.remove(exchangeId);
    _activeExchangeId = null;
  }
}
