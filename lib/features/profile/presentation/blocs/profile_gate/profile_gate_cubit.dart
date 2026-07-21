import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/state/safe_emit.dart';

import '../../../domain/entities/profile_status.dart';
import '../../../domain/usecases/get_my_profile_usecase.dart';
import 'profile_gate_state.dart';

/// App-scoped source of the signed-in user's [ProfileStatus] for the approval
/// PRE-gate: hide/disable like, photo-exchange, and subscribe until the
/// matchmaker approves the profile (browse + skip stay open; chat is never
/// gated). Reuses [GetMyProfileUseCase] — the same `GET /api/profile` read the
/// profile screen uses — fetched once when the user shell mounts (HomeScreen).
///
/// FAIL-OPEN by design: while loading, on fetch failure, or when the wire value
/// is unrecognised, [isGated] is `false`. The backend remains the real gate
/// (the reactive `PROFILE_NOT_APPROVED` classifier), so a transient
/// profile-fetch error can never lock an already-approved user out of acting.
///
/// Deviates from `CLAUDE.md` §2 (factory Cubits): this holds app-lifetime
/// state and is registered as a lazy singleton, like [UserSessionCubit].
class ProfileGateCubit extends Cubit<ProfileGateState>
    with SafeEmit<ProfileGateState> {
  final GetMyProfileUseCase _getMyProfile;

  ProfileGateCubit({required GetMyProfileUseCase getMyProfile})
      : _getMyProfile = getMyProfile,
        super(const ProfileGateInitial());

  /// Fetches the profile status once. No-op if already loading or resolved —
  /// safe to call on every shell mount. Use [refresh] to force a re-fetch
  /// (e.g. after the matchmaker approves and the user pulls to refresh).
  Future<void> ensureLoaded() async {
    if (state is ProfileGateLoading || state is ProfileGateResolved) return;
    await _load();
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    emit(const ProfileGateLoading());
    final result = await _getMyProfile();
    if (isClosed) return;
    result.fold(
      (failure) {
        // Fail-open — never block on a transient status-fetch error.
        AppLogger.warning(
          'Profile gate — status fetch failed, failing open: "${failure.message}"',
          tag: 'APPROVAL',
        );
        emit(const ProfileGateUnavailable());
      },
      (profile) => emit(ProfileGateResolved(profile.profileStatus)),
    );
  }

  /// The resolved status, or `null` while loading / on failure.
  ProfileStatus? get status =>
      state is ProfileGateResolved ? (state as ProfileGateResolved).status : null;

  /// `true` only when the status is KNOWN and not [ProfileStatus.visible].
  /// Fail-open otherwise (loading / unavailable / unknown → not gated).
  bool get isGated {
    final s = status;
    return s != null && s != ProfileStatus.visible;
  }
}
