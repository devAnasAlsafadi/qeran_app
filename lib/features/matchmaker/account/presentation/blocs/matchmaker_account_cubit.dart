import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/session/session_token_renewal.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../data/account_error_codes.dart';
import '../../domain/entities/matchmaker_me.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/deactivate_account_usecase.dart';
import '../../domain/usecases/get_me_usecase.dart';
import '../../domain/usecases/update_name_usecase.dart';
import '../../domain/usecases/upload_account_photo_usecase.dart';
import 'matchmaker_account_state.dart';

/// Screen-scoped controller for the matchmaker's own account: loads `/me`, then
/// drives name / photo / deactivate / change-password as single in-flight
/// mutations. Each publishes a one-shot outcome (eventVersion bump) + an
/// error-kind routing failures inline vs toast; name / photo successes
/// optimistically patch the cached `me`.
class MatchmakerAccountCubit extends Cubit<MatchmakerAccountState> with SafeEmit<MatchmakerAccountState> {
  final GetMeUseCase _getMe;
  final UpdateNameUseCase _updateName;
  final UploadAccountPhotoUseCase _uploadPhoto;
  final DeactivateAccountUseCase _deactivate;
  final ChangePasswordUseCase _changePassword;
  final SessionTokenRenewal _renewal;

  MatchmakerAccountCubit({
    required GetMeUseCase getMe,
    required UpdateNameUseCase updateName,
    required UploadAccountPhotoUseCase uploadPhoto,
    required DeactivateAccountUseCase deactivate,
    required ChangePasswordUseCase changePassword,
    required SessionTokenRenewal renewal,
  })  : _getMe = getMe,
        _updateName = updateName,
        _uploadPhoto = uploadPhoto,
        _deactivate = deactivate,
        _changePassword = changePassword,
        _renewal = renewal,
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
    _emitInFlight(MatchmakerAccountAction.savingName);
    final result = await _updateName(name);
    if (isClosed) return;
    result.fold(
      (failure) => _emitFailure('save name', failure.message,
          _kindFor(failure, MatchmakerAccountErrorCodes.validationError,
              MatchmakerAccountErrorKind.validation)),
      (_) => _emitSuccess(
        MatchmakerAccountOutcome.saveNameSuccess,
        me: state.me?.copyWith(name: name),
      ),
    );
  }

  Future<void> uploadPhoto(File image) async {
    if (state.isBusy) return;
    // Reuse the auth upload validation (ext + 2MB) before hitting the network.
    final invalidKey = _validateImage(image.path);
    if (invalidKey != null) {
      _emitFailure('photo validation', invalidKey,
          MatchmakerAccountErrorKind.generic);
      return;
    }
    _emitInFlight(MatchmakerAccountAction.uploadingPhoto);
    final result = await _uploadPhoto(image);
    if (isClosed) return;
    result.fold(
      (failure) => _emitFailure('upload photo', failure.message,
          MatchmakerAccountErrorKind.generic),
      (img) => _emitSuccess(
        MatchmakerAccountOutcome.uploadPhotoSuccess,
        me: state.me?.copyWith(image: img),
      ),
    );
  }

  Future<void> deactivate() async {
    if (state.isBusy) return;
    _emitInFlight(MatchmakerAccountAction.deactivating);
    final result = await _deactivate();
    if (isClosed) return;
    result.fold(
      (failure) => _emitFailure('deactivate', failure.message,
          MatchmakerAccountErrorKind.generic),
      (_) => _emitSuccess(MatchmakerAccountOutcome.deactivateSuccess),
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state.isBusy) return;
    // Backend requires newPassword.minLength == 6 — block early with a clear
    // message instead of letting a short password 400 and read as a confusing
    // "wrong current password". (Mirrors the photo pre-network validation.)
    if (newPassword.length < 6) {
      _emitFailure('password length',
          LocaleKeys.matchmaker_account_password_too_short,
          MatchmakerAccountErrorKind.generic);
      return;
    }
    _emitInFlight(MatchmakerAccountAction.changingPassword);
    // Its new token is adopted before any 401 is judged (C4).
    final result = await _renewal.run(() => _changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        ));
    if (isClosed) return;
    result.fold(
      // Only a wrong password is about the field, so only it sits under it.
      (failure) => _emitFailure('change password', failure.message,
          _kindFor(failure, MatchmakerAccountErrorCodes.invalidOldPassword,
              MatchmakerAccountErrorKind.incorrectPassword)),
      (_) => _emitSuccess(MatchmakerAccountOutcome.changePasswordSuccess),
    );
  }

  void _emitInFlight(MatchmakerAccountAction action) {
    emit(state.copyWith(
      inFlight: action,
      errorKind: MatchmakerAccountErrorKind.none,
      clearActionError: true,
    ));
  }

  void _emitSuccess(MatchmakerAccountOutcome outcome, {MatchmakerMe? me}) {
    emit(state.copyWith(
      clearInFlight: true,
      me: me,
      outcome: outcome,
      errorKind: MatchmakerAccountErrorKind.none,
      eventVersion: state.eventVersion + 1,
      clearActionError: true,
    ));
  }

  void _emitFailure(String tag, String message, MatchmakerAccountErrorKind kind) {
    AppLogger.warning('MATCHMAKER — $tag failed raw="$message"',
        tag: 'MM-ACCOUNT');
    emit(state.copyWith(
      clearInFlight: true,
      outcome: MatchmakerAccountOutcome.failure,
      errorKind: kind,
      eventVersion: state.eventVersion + 1,
      actionErrorKey: message,
    ));
  }

  /// [kind] (shown inline in its sheet) when [failure] carries [code]; any
  /// other failure toasts.
  MatchmakerAccountErrorKind _kindFor(Failure failure, String code,
          MatchmakerAccountErrorKind kind) =>
      failure is CodedServerFailure && failure.errorCode == code
          ? kind
          : MatchmakerAccountErrorKind.generic;

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
    // Its OWN key, not the profile one: the profile photo manager now allows
    // 5 MB (matching the server), while this endpoint has not been confirmed
    // past 2 MB. Sharing a string would make one of the two messages a lie.
    if (bytes > 2 * 1024 * 1024) {
      return LocaleKeys.matchmaker_account_photo_validation_size;
    }
    return null;
  }
}
