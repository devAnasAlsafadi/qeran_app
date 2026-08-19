import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../domain/entities/photo_slot.dart';
import '../../../domain/entities/profile_image.dart';
import '../../../domain/usecases/add_profile_images_usecase.dart';
import '../../../domain/usecases/delete_profile_image_usecase.dart';
import '../../../domain/usecases/get_profile_images_usecase.dart';
import '../../../domain/usecases/set_main_profile_image_usecase.dart';
import 'photo_manager_state.dart';

part 'photo_manager_cubit_mutations.dart';
part 'photo_manager_cubit_staging.dart';
part 'photo_manager_cubit_upload.dart';

/// Drives the single photo manager used by both registration and profile
/// edit. It holds server photos and locally staged files side by side so
/// the 5-photo cap, the main-photo choice and the grid all reason about
/// one list rather than two.
class PhotoManagerCubit extends Cubit<PhotoManagerState>
    with SafeEmit<PhotoManagerState> {
  PhotoManagerCubit({
    required PhotoManagerMode mode,
    required GetProfileImagesUseCase getImages,
    required AddProfileImagesUseCase addImages,
    required DeleteProfileImageUseCase deleteImage,
    required SetMainProfileImageUseCase setMain,
    required SharedPrefService sharedPrefs,
  }) : _getImages = getImages,
       _addImages = addImages,
       _deleteImage = deleteImage,
       _setMain = setMain,
       _sharedPrefs = sharedPrefs,
       super(PhotoManagerState(mode: mode));

  final GetProfileImagesUseCase _getImages;
  final AddProfileImagesUseCase _addImages;
  final DeleteProfileImageUseCase _deleteImage;
  final SetMainProfileImageUseCase _setMain;
  final SharedPrefService _sharedPrefs;

  /// Loads the photos already on the server. At registration this is
  /// normally empty, but it is still fetched so a user who returns to the
  /// step does not see their earlier uploads vanish.
  Future<void> load() async {
    emit(state.copyWith(status: PhotoManagerStatus.loading, clearError: true));
    final result = await _getImages();
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PhotoManagerStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (images) => emit(
        state.copyWith(
          status: PhotoManagerStatus.loaded,
          serverImages: images,
          clearError: true,
        ),
      ),
    );
  }

  /// Registration-only: records that the step is done and moves on. The
  /// behaviour is unchanged from the standalone upload screen.
  Future<void> skip() async {
    if (state.mode != PhotoManagerMode.onboarding) return;
    AppLogger.info('User skipped photo upload', tag: 'PHOTO_MANAGER');
    await _sharedPrefs.save(StorageKeys.uploadedPhotos, true);
    if (isClosed) return;
    _event(PhotoManagerEvent.finished);
  }

  Future<void> _reloadAfterMutation(
    PhotoManagerEvent success, {
    bool clearStaged = false,
  }) async {
    final refreshed = await _getImages();
    if (isClosed) return;
    refreshed.fold(
      (failure) => emit(
        state.copyWith(
          clearInFlight: true,
          event: PhotoManagerEvent.actionFailure,
          eventVersion: state.eventVersion + 1,
          errorMessage: failure.message,
        ),
      ),
      (images) => emit(
        state.copyWith(
          status: PhotoManagerStatus.loaded,
          serverImages: images,
          stagedPaths: clearStaged ? const [] : null,
          clearStagedMain: clearStaged,
          clearInFlight: true,
          event: success,
          eventVersion: state.eventVersion + 1,
          clearError: true,
        ),
      ),
    );
  }

  void _event(PhotoManagerEvent event, {String? errorMessage}) {
    emit(
      state.copyWith(
        event: event,
        eventVersion: state.eventVersion + 1,
        errorMessage: errorMessage,
        clearError: errorMessage == null,
      ),
    );
  }
}
