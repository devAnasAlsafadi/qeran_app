import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/state/safe_emit.dart';

import '../../../domain/entities/my_profile.dart';
import '../../../domain/usecases/get_my_profile_usecase.dart';
import '../../../domain/usecases/update_display_name_usecase.dart';
import '../profile_gate/profile_gate_cubit.dart';
import 'display_name_state.dart';

/// The backend's machine-readable rejection when an edit lands inside the
/// 7-day cooldown. Preferred over matching the Arabic message.
const String kDisplayNameLockedCode = 'DISPLAY_NAME_LOCKED';

/// Drives the name screen. Reads the profile fresh on mount — the lock window
/// must be current at the moment the editor opens, not whenever the app-scoped
/// gate last refreshed — and writes through `PUT /api/profile`.
class DisplayNameCubit extends Cubit<DisplayNameState>
    with SafeEmit<DisplayNameState> {
  final GetMyProfileUseCase _getMyProfile;
  final UpdateDisplayNameUseCase _updateDisplayName;
  final ProfileGateCubit _profileGate;

  DisplayNameCubit({
    required GetMyProfileUseCase getMyProfile,
    required UpdateDisplayNameUseCase updateDisplayName,
    required ProfileGateCubit profileGate,
  }) : _getMyProfile = getMyProfile,
       _updateDisplayName = updateDisplayName,
       _profileGate = profileGate,
       super(const DisplayNameState());

  Future<void> load() async {
    emit(state.copyWith(status: DisplayNameStatus.loading, clearError: true));
    final result = await _getMyProfile();
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DisplayNameStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (profile) => emit(
        state.copyWith(status: DisplayNameStatus.loaded, profile: profile),
      ),
    );
  }

  /// Writes [name] and re-seeds from the profile the server returns. The
  /// app-scoped gate is updated from the same payload so the settings hero and
  /// the default-name banner change without a second read.
  Future<void> save(String name) async {
    final trimmed = name.trim();
    if (state.saving || trimmed.isEmpty || trimmed == state.displayName) return;

    emit(state.copyWith(saving: true, clearError: true));
    final result = await _updateDisplayName(trimmed);
    if (isClosed) return;
    await result.fold(
      (failure) => _onSaveFailure(failure),
      (profile) async => _onSaveSuccess(profile),
    );
  }

  void _onSaveSuccess(MyProfile profile) {
    _profileGate.applyProfile(profile);
    emit(
      state.copyWith(
        profile: profile,
        status: DisplayNameStatus.loaded,
        saving: false,
        event: DisplayNameEvent.saved,
        eventVersion: state.eventVersion + 1,
        clearError: true,
      ),
    );
  }

  Future<void> _onSaveFailure(Failure failure) async {
    AppLogger.warning(
      'Display name save failed message="${failure.message}"',
      tag: 'PROFILE',
    );
    emit(
      state.copyWith(
        saving: false,
        event: DisplayNameEvent.saveFailed,
        eventVersion: state.eventVersion + 1,
        // The backend's cooldown copy is already Arabic and specific; showing
        // it verbatim beats a generic client string.
        errorMessage: failure.message,
      ),
    );
    // A cooldown rejection means our view of the lock is stale — the window we
    // were rendering as open is not. Re-read so the form locks itself.
    if (failure is CodedServerFailure &&
        failure.errorCode == kDisplayNameLockedCode) {
      await _refreshQuietly();
    }
  }

  /// Re-reads the profile without a loading flash — used after a rejection,
  /// where the form is already on screen and must not blank.
  Future<void> _refreshQuietly() async {
    final result = await _getMyProfile();
    if (isClosed) return;
    result.fold(
      (_) {},
      (profile) => emit(
        state.copyWith(status: DisplayNameStatus.loaded, profile: profile),
      ),
    );
  }
}
