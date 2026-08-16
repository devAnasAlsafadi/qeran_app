import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/state/safe_emit.dart';

import '../../../domain/entities/my_profile.dart';
import '../../../domain/usecases/get_my_profile_usecase.dart';
import '../../../domain/usecases/update_profile_usecase.dart';
import '../profile_gate/profile_gate_cubit.dart';
import 'display_name_state.dart';

/// Drives the name screen. Reads the profile fresh on mount, then writes both
/// names through `PUT /api/profile` in a single call. Neither name is locked —
/// the backend has no cooldown.
class DisplayNameCubit extends Cubit<DisplayNameState>
    with SafeEmit<DisplayNameState> {
  final GetMyProfileUseCase _getMyProfile;
  final UpdateProfileUseCase _updateProfile;
  final ProfileGateCubit _profileGate;

  DisplayNameCubit({
    required GetMyProfileUseCase getMyProfile,
    required UpdateProfileUseCase updateProfile,
    required ProfileGateCubit profileGate,
  }) : _getMyProfile = getMyProfile,
       _updateProfile = updateProfile,
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

  /// Writes both names and re-seeds from the profile the server returns. The
  /// app-scoped gate is updated from the same payload so the settings hero and
  /// the default-name banner change without a second read.
  ///
  /// [displayName] is required by the backend on every call. [realName] is
  /// resolved against the loaded baseline by [_realNamePayload].
  Future<void> save({required String displayName, String? realName}) async {
    final trimmedDisplayName = displayName.trim();
    if (state.saving || trimmedDisplayName.isEmpty) return;

    final realNamePayload = _realNamePayload(realName);
    // The pair decides, not the display name alone: a null payload means
    // realName is unchanged, so only when the display name ALSO matches the
    // baseline is there nothing to write.
    if (trimmedDisplayName == state.displayName && realNamePayload == null) {
      return;
    }

    emit(state.copyWith(saving: true, clearError: true));
    final result = await _updateProfile(
      displayName: trimmedDisplayName,
      realName: realNamePayload,
    );
    if (isClosed) return;
    result.fold(_onSaveFailure, _onSaveSuccess);
  }

  /// What to send for `realName`, per the backend's three-way contract:
  /// null omits the key (leave unchanged), `''` clears the stored value, and
  /// anything else sets it.
  ///
  /// Diffing against the loaded profile is what lets "the member never touched
  /// this field" and "the member emptied it" resolve differently without the
  /// form having to track whether it was focused.
  String? _realNamePayload(String? input) {
    final current = input?.trim() ?? '';
    // `state.realName` already trims and normalises blank to null, so an
    // absent name and an empty one compare equal here.
    final baseline = state.realName ?? '';
    if (current == baseline) return null;
    return current;
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

  void _onSaveFailure(Failure failure) {
    AppLogger.warning(
      'Profile names save failed message="${failure.message}"',
      tag: 'PROFILE',
    );
    emit(
      state.copyWith(
        saving: false,
        event: DisplayNameEvent.saveFailed,
        eventVersion: state.eventVersion + 1,
        // The backend's copy is already Arabic and specific; showing it
        // verbatim beats a generic client string.
        errorMessage: failure.message,
      ),
    );
  }
}
