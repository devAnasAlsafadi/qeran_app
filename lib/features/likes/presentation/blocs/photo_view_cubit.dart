import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../application/photo_view_session_clock.dart';
import '../../domain/entities/photo_view_permission.dart';
import '../../domain/entities/photo_view_session.dart';
import '../../domain/usecases/begin_photo_view_usecase.dart';
import '../../domain/usecases/get_photo_view_permission_usecase.dart';
import 'photo_view_state.dart';

class PhotoViewCubit extends Cubit<PhotoViewState>
    with SafeEmit<PhotoViewState> {
  final String targetUserId;
  final GetPhotoViewPermissionUseCase _getPermission;
  final BeginPhotoViewUseCase _beginView;
  final PhotoViewSessionClock _sessionClock;

  Timer? _ticker;
  int? _activeExchangeId;
  bool _loading = false;

  PhotoViewCubit({
    required this.targetUserId,
    required GetPhotoViewPermissionUseCase getPermission,
    required BeginPhotoViewUseCase beginView,
    required PhotoViewSessionClock sessionClock,
  }) : _getPermission = getPermission,
       _beginView = beginView,
       _sessionClock = sessionClock,
       super(const PhotoViewState());

  Future<void> load() async {
    if (_loading) return;
    _loading = true;

    if (state.phase == PhotoViewPhase.viewing) {
      emit(state.copyWith(isConcealed: true, clearError: true));
    } else {
      emit(
        PhotoViewState(
          phase: PhotoViewPhase.loading,
          permission: state.permission,
        ),
      );
    }

    final result = await _getPermission(targetUserId);
    _loading = false;
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        PhotoViewState(
          phase: PhotoViewPhase.failure,
          permission: state.permission,
          errorMessage: failure.message,
        ),
      ),
      _applyPermission,
    );
  }

  Future<void> beginViewing() async {
    if (state.phase != PhotoViewPhase.available || state.isStarting) return;
    final exchangeId = state.permission?.photoExchangeId;
    if (exchangeId == null) return;

    emit(state.copyWith(isStarting: true, clearActionError: true));
    final result = await _beginView(exchangeId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          isStarting: false,
          actionErrorMessage: failure.message,
          eventVersion: state.eventVersion + 1,
        ),
      ),
      _startSession,
    );
  }

  /// Conceal before the OS snapshots an inactive/background route. On resume
  /// [load] re-checks the authoritative permission before showing bytes again.
  void conceal() {
    if (state.phase == PhotoViewPhase.viewing && !state.isConcealed) {
      emit(state.copyWith(isConcealed: true));
    }
  }

  /// The protected image endpoint returned 403. Lock immediately, clear the
  /// memory-only providers via rebuild/dispose, then reconcile silently.
  void markImageAccessConsumed() {
    if (state.phase == PhotoViewPhase.consumed) return;
    // The visible countdown is gone, so the end of the window has to announce
    // itself — but only to someone who was actually looking at the photos. A
    // 403 that arrives before any reveal is not an expiry they witnessed.
    final wasViewing = state.phase == PhotoViewPhase.viewing;
    _stopWindow();
    emit(
      PhotoViewState(
        phase: PhotoViewPhase.consumed,
        permission: state.permission,
        justExpired: wasViewing,
        eventVersion: wasViewing ? state.eventVersion + 1 : state.eventVersion,
      ),
    );
    unawaited(_refreshAfterLock());
  }

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

  @override
  Future<void> close() {
    // Keep the singleton monotonic clock alive if the route closes during the
    // window; a newly scoped cubit can resume the same remaining seconds.
    _ticker?.cancel();
    _ticker = null;
    _activeExchangeId = null;
    return super.close();
  }
}
