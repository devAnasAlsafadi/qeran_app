import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';

import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../domain/usecases/upload_images_usecase.dart';
import 'photo_upload_state.dart';

class PhotoUploadCubit extends Cubit<PhotoUploadState> with SafeEmit<PhotoUploadState> {
  final UploadImagesUseCase _uploadImages;
  final SharedPrefService _sharedPrefs;

  PhotoUploadCubit({
    required UploadImagesUseCase uploadImages,
    required SharedPrefService sharedPrefs,
  }) : _uploadImages = uploadImages,
       _sharedPrefs = sharedPrefs,
       super(const PhotoUploadInitial());

  // ─── Image Management ──────────────────────────────────────────

  /// Add an image by its file path. Max 5 images.
  void addImage(String path) {
    if (!state.canAddMore) {
      AppLogger.warning('Max 5 images allowed', tag: 'PHOTO_UPLOAD');
      return;
    }

    final validationError = _validateImage(path);
    if (validationError != null) {
      AppLogger.warning('Image rejected: $validationError', tag: 'PHOTO_UPLOAD');
      emit(PhotoUploadValidationError(
        errorMessage: validationError,
        imagePaths: state.imagePaths,
        primaryIndex: state.primaryIndex,
      ));
      return;
    }

    final updatedPaths = [...state.imagePaths, path];

    AppLogger.debug(
      'Image added -> count=${updatedPaths.length}',
      tag: 'PHOTO_UPLOAD',
    );

    emit(
      PhotoUploadEditing(
        imagePaths: updatedPaths,
        primaryIndex: state.primaryIndex,
      ),
    );
  }

  /// Remove an image at [index] and adjust primary if needed.
  void removeImage(int index) {
    final paths = state.imagePaths;
    if (index < 0 || index >= paths.length) return;

    final updatedPaths = [...paths]..removeAt(index);
    int newPrimary = state.primaryIndex;

    if (updatedPaths.isEmpty) {
      newPrimary = 0;
    } else if (index == newPrimary) {
      // Primary was removed → reset to first image
      newPrimary = 0;
    } else if (index < newPrimary) {
      // An image before primary was removed → shift index down
      newPrimary--;
    }

    AppLogger.debug(
      'Image removed at $index -> count=${updatedPaths.length}, '
      'primary=$newPrimary',
      tag: 'PHOTO_UPLOAD',
    );

    if (updatedPaths.isEmpty) {
      emit(const PhotoUploadInitial());
    } else {
      emit(
        PhotoUploadEditing(imagePaths: updatedPaths, primaryIndex: newPrimary),
      );
    }
  }

  /// Mark the image at [index] as primary.
  void setPrimary(int index) {
    if (index < 0 || index >= state.imagePaths.length) return;
    if (index == state.primaryIndex) return; // already primary

    AppLogger.debug('Primary changed -> $index', tag: 'PHOTO_UPLOAD');

    emit(PhotoUploadEditing(imagePaths: state.imagePaths, primaryIndex: index));
  }

  // ─── Upload ────────────────────────────────────────────────────

  /// Reorder images so primary is at index 0, then upload.
  Future<void> uploadImages() async {
    final paths = state.imagePaths;
    final primary = state.primaryIndex;

    if (paths.isEmpty) return;

    // Belt-and-suspenders: re-validate all images before upload
    for (final path in paths) {
      final error = _validateImage(path);
      if (error != null) {
        AppLogger.warning(
          'Pre-upload validation failed for $path: $error',
          tag: 'PHOTO_UPLOAD',
        );
        emit(PhotoUploadValidationError(
          errorMessage: error,
          imagePaths: paths,
          primaryIndex: primary,
        ));
        return;
      }
    }

    emit(PhotoUploadUploading(imagePaths: paths, primaryIndex: primary));

    // Place primary image at index 0 as the backend requires
    final reorderedPaths = _reorderForUpload(paths, primary);
    final files = reorderedPaths.map((p) => File(p)).toList();

    AppLogger.debug(
      'Uploading ${files.length} images (primary at index 0)',
      tag: 'PHOTO_UPLOAD',
    );

    final result = await _uploadImages(images: files);

    await result.fold(
      (failure) async {
        AppLogger.error(
          'Upload failed: ${failure.message}',
          tag: 'PHOTO_UPLOAD',
        );
        emit(
          PhotoUploadFailure(
            errorMessage: failure.message,
            imagePaths: paths,
            primaryIndex: primary,
          ),
        );
      },
      (message) async {
        AppLogger.info('Upload success: $message', tag: 'PHOTO_UPLOAD');
        await _sharedPrefs.save(StorageKeys.uploadedPhotos, true);
        emit(PhotoUploadSuccess(successMessage: message));
      },
    );
  }

  /// Skip photo upload — persist flag and navigate.
  Future<void> skipUpload() async {
    AppLogger.info('User skipped photo upload', tag: 'PHOTO_UPLOAD');
    await _sharedPrefs.save(StorageKeys.uploadedPhotos, true);
    emit(const PhotoUploadSuccess());
  }

  // ─── Helpers ───────────────────────────────────────────────────

  /// Returns a translation key if the image is invalid, or null if it passes.
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

    const maxBytes = 2 * 1024 * 1024; // 2 MB
    if (bytes > maxBytes) {
      return LocaleKeys.auth_photo_validation_size;
    }

    return null;
  }

  /// Returns a new list with the primary image moved to index 0.
  List<String> _reorderForUpload(List<String> paths, int primaryIdx) {
    if (paths.isEmpty || primaryIdx == 0) return List.of(paths);

    final reordered = <String>[paths[primaryIdx]];
    for (int i = 0; i < paths.length; i++) {
      if (i != primaryIdx) reordered.add(paths[i]);
    }
    return reordered;
  }
}
