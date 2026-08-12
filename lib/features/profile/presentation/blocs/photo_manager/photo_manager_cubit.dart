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

  static const Set<String> _allowedExtensions = {'.jpg', '.jpeg', '.png'};
  static const int _maxBytes = 2 * 1024 * 1024;

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

  /// Stages a picked file locally. Nothing is sent until [upload] runs.
  void addImage(String path) {
    if (state.isBusy) return;
    if (!state.canAddMore) {
      _event(PhotoManagerEvent.maxReached);
      return;
    }
    final validation = _validate(path);
    if (validation != null) {
      _event(PhotoManagerEvent.validationFailure, errorMessage: validation);
      return;
    }
    // The very first photo of an empty profile is the main one by default,
    // matching what registration has always done.
    final isFirstEverPhoto = state.totalCount == 0;
    emit(
      state.copyWith(
        stagedPaths: [...state.stagedPaths, path],
        stagedMainPath: isFirstEverPhoto ? path : null,
        clearError: true,
      ),
    );
  }

  /// Drops a staged file. No request — it was never uploaded.
  void removeStaged(String path) {
    if (state.isBusy) return;
    final remaining = [...state.stagedPaths]..remove(path);
    final losingMain = state.stagedMainPath == path;
    emit(
      state.copyWith(
        stagedPaths: remaining,
        // Promote the next staged photo so the user is never left with a
        // staged-only set and no main.
        stagedMainPath: losingMain && remaining.isNotEmpty && !_serverHasMain
            ? remaining.first
            : null,
        clearStagedMain: losingMain && (remaining.isEmpty || _serverHasMain),
      ),
    );
  }

  /// Deletes a photo that already lives on the server.
  Future<void> deleteServerImage(String imageId) async {
    if (state.isBusy) return;
    emit(
      state.copyWith(
        inFlight: PhotoManagerAction.delete,
        inFlightImageId: imageId,
        clearError: true,
      ),
    );
    final result = await _deleteImage(imageId);
    await _finishMutation(result, PhotoManagerEvent.deleted);
  }

  /// Promotes a slot to main. A server photo goes through the API; a
  /// staged photo is only recorded locally and takes effect after upload.
  Future<void> setMain(PhotoSlot slot) async {
    if (state.isBusy) return;
    switch (slot) {
      case StagedPhotoSlot(:final path):
        emit(state.copyWith(stagedMainPath: path, clearError: true));
        _event(PhotoManagerEvent.mainChanged);
      case ServerPhotoSlot(:final id):
        emit(
          state.copyWith(
            inFlight: PhotoManagerAction.setMain,
            inFlightImageId: id,
            clearError: true,
            clearStagedMain: true,
          ),
        );
        final result = await _setMain(id);
        await _finishMutation(result, PhotoManagerEvent.mainChanged);
    }
  }

  /// Uploads every staged file in one multipart request, main photo first.
  ///
  /// On failure the staged files are deliberately kept so the user can
  /// retry without re-picking them.
  Future<void> upload() async {
    if (state.isBusy || !state.hasStaged) return;

    for (final path in state.stagedPaths) {
      final error = _validate(path);
      if (error != null) {
        _event(PhotoManagerEvent.validationFailure, errorMessage: error);
        return;
      }
    }

    final knownIds = state.serverImages.map((i) => i.id).toSet();
    final hadServerImages = knownIds.isNotEmpty;
    final wantsStagedMain = state.stagedMainPath != null;
    final ordered = _mainFirst(state.stagedPaths, state.stagedMainPath);

    emit(
      state.copyWith(
        inFlight: PhotoManagerAction.upload,
        clearError: true,
      ),
    );

    final result = await _addImages(
      ordered.map(File.new).toList(growable: false),
    );
    if (isClosed) return;

    String? failure;
    result.fold<void>((f) => failure = f.message, (_) {});
    if (failure != null) {
      AppLogger.error('Photo upload failed: $failure', tag: 'PHOTO_MANAGER');
      emit(
        state.copyWith(
          clearInFlight: true,
          event: PhotoManagerEvent.actionFailure,
          eventVersion: state.eventVersion + 1,
          errorMessage: failure,
        ),
      );
      return;
    }

    await _sharedPrefs.save(StorageKeys.uploadedPhotos, true);

    // The upload endpoint returns no ids, so the newly created photos are
    // discovered by diffing the refreshed list against the ids we already
    // had. An empty profile needs no promotion — the backend treats the
    // first uploaded file as main.
    if (wantsStagedMain && hadServerImages) {
      await _promoteFirstNewImage(knownIds);
      if (isClosed) return;
    }

    // Registration moves on to the app; profile edit stays put and just
    // confirms the photos are pending review.
    await _reloadAfterMutation(
      state.mode == PhotoManagerMode.onboarding
          ? PhotoManagerEvent.finished
          : PhotoManagerEvent.uploaded,
      clearStaged: true,
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

  bool get _serverHasMain => state.serverImages.any((i) => i.isProfile);

  /// Finds the images that appeared since [knownIds] and promotes the
  /// first of them, which is the one we uploaded at index 0.
  Future<void> _promoteFirstNewImage(Set<String> knownIds) async {
    final refreshed = await _getImages();
    if (isClosed) return;
    final added = refreshed.fold<List<OwnerImage>>(
      (_) => const [],
      (images) =>
          images.where((i) => !knownIds.contains(i.id)).toList(growable: false),
    );
    if (added.isEmpty) return;
    await _setMain(added.first.id);
  }

  Future<void> _finishMutation(
    Either<Failure, Unit> result,
    PhotoManagerEvent success,
  ) async {
    if (isClosed) return;
    String? failure;
    result.fold<void>((f) => failure = f.message, (_) {});
    if (failure != null) {
      emit(
        state.copyWith(
          clearInFlight: true,
          event: PhotoManagerEvent.actionFailure,
          eventVersion: state.eventVersion + 1,
          errorMessage: failure,
        ),
      );
      return;
    }
    await _reloadAfterMutation(success);
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

  /// Returns [paths] with [main] moved to the front. The backend treats
  /// the first file in the multipart body as the profile photo.
  List<String> _mainFirst(List<String> paths, String? main) {
    if (main == null || paths.isEmpty || paths.first == main) {
      return List.of(paths);
    }
    return [main, ...paths.where((p) => p != main)];
  }

  /// Returns a locale key when the file is unusable, or null when it passes.
  String? _validate(String path) {
    final file = File(path);
    if (!file.existsSync()) return LocaleKeys.auth_photo_validation_not_found;
    final extension = path.contains('.')
        ? path.substring(path.lastIndexOf('.')).toLowerCase()
        : '';
    if (!_allowedExtensions.contains(extension)) {
      return LocaleKeys.auth_photo_validation_type;
    }
    try {
      if (file.lengthSync() > _maxBytes) {
        return LocaleKeys.auth_photo_validation_size;
      }
    } catch (_) {
      return LocaleKeys.auth_photo_validation_read_error;
    }
    return null;
  }
}
