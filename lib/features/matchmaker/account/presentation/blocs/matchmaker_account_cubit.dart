import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/usecases/deactivate_account_usecase.dart';
import '../../domain/usecases/get_me_usecase.dart';
import '../../domain/usecases/update_name_usecase.dart';
import '../../domain/usecases/upload_account_photo_usecase.dart';
import 'matchmaker_account_state.dart';

/// Screen-scoped controller for the matchmaker's own account. Loads `/me` on
/// mount, then drives name / photo / deactivate as single in-flight mutations.
/// Each completed mutation publishes a one-shot outcome (eventVersion bump) the
/// screen turns into a snackbar — and, for deactivate, a session clear + login
/// redirect. Name / photo successes optimistically patch the cached `me`.
class MatchmakerAccountCubit extends Cubit<MatchmakerAccountState> {
  final GetMeUseCase _getMe;
  final UpdateNameUseCase _updateName;
  final UploadAccountPhotoUseCase _uploadPhoto;
  final DeactivateAccountUseCase _deactivate;

  MatchmakerAccountCubit({
    required GetMeUseCase getMe,
    required UpdateNameUseCase updateName,
    required UploadAccountPhotoUseCase uploadPhoto,
    required DeactivateAccountUseCase deactivate,
  })  : _getMe = getMe,
        _updateName = updateName,
        _uploadPhoto = uploadPhoto,
        _deactivate = deactivate,
        super(const MatchmakerAccountState());

  Future<void> load() async {
    emit(state.copyWith(
      status: MatchmakerAccountStatus.loading,
      clearLoadError: true,
    ));
    final result = await _getMe();
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'MATCHMAKER — load me failed raw="${failure.message}"',
          tag: 'MM-ACCOUNT',
        );
        emit(state.copyWith(
          status: MatchmakerAccountStatus.failure,
          loadErrorKey: failure.message,
        ));
      },
      (me) => emit(state.copyWith(
        status: MatchmakerAccountStatus.loaded,
        me: me,
        clearLoadError: true,
      )),
    );
  }

  Future<void> updateName(String name) async {
    if (state.isBusy) return;
    emit(state.copyWith(
      inFlight: MatchmakerAccountAction.savingName,
      clearActionError: true,
    ));
    final result = await _updateName(name);
    if (isClosed) return;
    result.fold(
      (failure) => _emitActionFailure('save name', failure.message),
      (_) => emit(state.copyWith(
        clearInFlight: true,
        me: state.me?.copyWith(name: name),
        outcome: MatchmakerAccountOutcome.saveNameSuccess,
        eventVersion: state.eventVersion + 1,
        clearActionError: true,
      )),
    );
  }

  Future<void> uploadPhoto(File image) async {
    if (state.isBusy) return;
    // Reuse the auth upload validation (ext + 2MB) before hitting the network.
    final invalidKey = _validateImage(image.path);
    if (invalidKey != null) {
      _emitActionFailure('photo validation', invalidKey);
      return;
    }
    emit(state.copyWith(
      inFlight: MatchmakerAccountAction.uploadingPhoto,
      clearActionError: true,
    ));
    final result = await _uploadPhoto(image);
    if (isClosed) return;
    result.fold(
      (failure) => _emitActionFailure('upload photo', failure.message),
      (img) => emit(state.copyWith(
        clearInFlight: true,
        me: state.me?.copyWith(image: img),
        outcome: MatchmakerAccountOutcome.uploadPhotoSuccess,
        eventVersion: state.eventVersion + 1,
        clearActionError: true,
      )),
    );
  }

  Future<void> deactivate() async {
    if (state.isBusy) return;
    emit(state.copyWith(
      inFlight: MatchmakerAccountAction.deactivating,
      clearActionError: true,
    ));
    final result = await _deactivate();
    if (isClosed) return;
    result.fold(
      (failure) => _emitActionFailure('deactivate', failure.message),
      (_) => emit(state.copyWith(
        clearInFlight: true,
        outcome: MatchmakerAccountOutcome.deactivateSuccess,
        eventVersion: state.eventVersion + 1,
        clearActionError: true,
      )),
    );
  }

  void _emitActionFailure(String tag, String message) {
    AppLogger.warning('MATCHMAKER — $tag failed raw="$message"',
        tag: 'MM-ACCOUNT');
    emit(state.copyWith(
      clearInFlight: true,
      outcome: MatchmakerAccountOutcome.failure,
      eventVersion: state.eventVersion + 1,
      actionErrorKey: message,
    ));
  }

  /// Ported from `PhotoUploadCubit._validateImage` — jpg/jpeg/png ≤2MB. Returns
  /// a locale key when invalid, else null.
  String? _validateImage(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return LocaleKeys.auth_photo_validation_not_found;
    }
    final ext = path.contains('.')
        ? path.substring(path.lastIndexOf('.')).toLowerCase()
        : '';
    if (!{'.jpg', '.jpeg', '.png'}.contains(ext)) {
      return LocaleKeys.auth_photo_validation_type;
    }
    int bytes;
    try {
      bytes = file.lengthSync();
    } catch (_) {
      return LocaleKeys.auth_photo_validation_read_error;
    }
    if (bytes > 2 * 1024 * 1024) {
      return LocaleKeys.auth_photo_validation_size;
    }
    return null;
  }
}
