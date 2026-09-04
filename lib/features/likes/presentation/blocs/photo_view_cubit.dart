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

part 'photo_view_cubit_window.dart';

class PhotoViewCubit extends Cubit<PhotoViewState>
    with SafeEmit<PhotoViewState> {
  final String targetUserId;
  final GetPhotoViewPermissionUseCase _getPermission;
  final BeginPhotoViewUseCase _beginView;
  final PhotoViewSessionClock _sessionClock;

  Timer? _ticker;
  int? _activeExchangeId;

  /// The re-verification currently in flight, or null. Held as a FUTURE rather
  /// than a flag so a press arriving mid-read can wait for the answer instead
  /// of being judged against a phase that is still `loading`.
  Future<void>? _inFlightLoad;

  /// Counts the authoritative facts this cubit has learned. A permission GET
  /// issued BEFORE one of them was answered from a snapshot that predates it,
  /// so applying its result would undo the newer fact.
  ///
  /// Two things bump it, and both are things the server already knows and an
  /// older read does not: a completed reveal POST, and a 403 saying the window
  /// is dead. The second matters most — a read issued before a revocation
  /// still says "viewing", and applying it would resurrect a window the server
  /// has already closed.
  ///
  /// Every bump is paired with its own `emit`, which is what makes dropping a
  /// read safe: the write that trips the guard has already replaced whatever
  /// [load] put on screen, so nothing is left stranded at `loading`.
  int _authorityVersion = 0;

  PhotoViewCubit({
    required this.targetUserId,
    required GetPhotoViewPermissionUseCase getPermission,
    required BeginPhotoViewUseCase beginView,
    required PhotoViewSessionClock sessionClock,
  }) : _getPermission = getPermission,
       _beginView = beginView,
       _sessionClock = sessionClock,
       super(const PhotoViewState());

  /// Concurrent callers join the read already running rather than starting a
  /// second one, and get a future they can wait on.
  Future<void> load() =>
      _inFlightLoad ??= _read().whenComplete(() => _inFlightLoad = null);

  Future<void> _read() async {
    // Stamped at ISSUE time and compared at apply time, so this drops exactly
    // the reads that are OUT OF DATE. It deliberately does not ask "are we
    // viewing?" — that question would also swallow the re-verification that
    // catches a REVOKED window on resume, turning this into a leak. A read
    // issued after the newest fact always applies, revocation included.
    final issuedAt = _authorityVersion;

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
    if (isClosed) return;
    // Before the fold, not inside it: a GET that FAILS after a reveal landed
    // would otherwise clobber the open window into `failure`.
    if (_authorityVersion != issuedAt) return;
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
    // A re-verification already in flight is the authority on whether this
    // press is still allowed, so DEFER to it rather than race it. Losing that
    // scheduling coin-flip used to leave the gate below reading `loading`, and
    // the press vanished with no feedback of any kind.
    //
    // Waiting is strictly safer than widening the gate to accept `loading`:
    // that would POST against an exchangeId taken from a permission the cubit
    // is in the middle of re-checking. This waits for the answer and then
    // applies the same gate, so a press can still only proceed on a permission
    // currently believed to be `available` — and if the read says the window
    // is gone, the member sees that rather than nothing.
    await _inFlightLoad;
    if (isClosed) return;
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
      (session) {
        // The POST changed server state. Any permission read already in flight
        // was answered before that, so it can no longer speak for this cubit.
        _authorityVersion += 1;
        _startSession(session);
      },
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
    // A read in flight was issued before this 403 and still believes the
    // window is open. Fail closed: it must not be allowed to reopen it.
    _authorityVersion += 1;
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
