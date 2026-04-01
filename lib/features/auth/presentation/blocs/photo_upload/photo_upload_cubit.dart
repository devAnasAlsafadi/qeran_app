import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';

import '../../../domain/usecases/upload_images_usecase.dart';
import 'photo_upload_state.dart';

class PhotoUploadCubit extends Cubit<PhotoUploadState> {
  final UploadImagesUseCase _uploadImagesUseCase;
  final SharedPrefService _sharedPrefs;

  PhotoUploadCubit({
    required UploadImagesUseCase uploadImagesUseCase,
    required SharedPrefService sharedPrefService,
  })  : _uploadImagesUseCase = uploadImagesUseCase,
        _sharedPrefs = sharedPrefService,
        super(PhotoUploadInitial());

  /// List of selected image files
  List<File> images = [];

  /// Index of the primary (main) image
  int primaryIndex = 0;

  /// Add a single image to the list (max 6)
  void addImage(File imageFile) {
    if (images.length < 6) {
      images.add(imageFile);
      AppLogger.debug(
        'Image added: count=${images.length}',
        tag: 'PHOTO_UPLOAD',
      );
    } else {
      AppLogger.warning('Max 6 images allowed', tag: 'PHOTO_UPLOAD');
    }
  }

  /// Remove an image by index and adjust primaryIndex if needed
  void removeImage(int index) {
    if (index >= 0 && index < images.length) {
      images.removeAt(index);

      // Adjust primary index if the primary image was removed
      if (primaryIndex >= images.length) {
        primaryIndex = images.length > 0 ? images.length - 1 : 0;
      }

      AppLogger.debug(
        'Image removed at index=$index, primaryIndex=$primaryIndex',
        tag: 'PHOTO_UPLOAD',
      );
    }
  }

  /// Set an image as primary (by index)
  void setPrimary(int index) {
    if (index >= 0 && index < images.length) {
      primaryIndex = index;
      AppLogger.debug(
        'Primary image set to index=$index',
        tag: 'PHOTO_UPLOAD',
      );
    }
  }

  /// Upload images with primary image at index 0
  Future<void> uploadImages() async {
    if (images.isEmpty) {
      emit(PhotoUploadFailure('Please select at least one image'));
      return;
    }

    emit(PhotoUploadInProgress());

    // Reorder: move primary image to index 0
    final reorderedImages = _reorderImagesToPrimary();

    AppLogger.debug(
      'Uploading ${reorderedImages.length} images with primary at index 0',
      tag: 'PHOTO_UPLOAD',
    );

    final result = await _uploadImagesUseCase.call(images: reorderedImages);

    result.fold(
      (failure) {
        AppLogger.error(
          'Upload failed: ${failure.message}',
          tag: 'PHOTO_UPLOAD',
        );
        emit(PhotoUploadFailure(failure.message ?? 'Upload failed'));
      },
      (successResponse) async {
        AppLogger.info(
          'Images uploaded successfully',
          tag: 'PHOTO_UPLOAD',
        );

        // Save flag to SharedPrefs
        await _sharedPrefs.save(StorageKeys.uploadedPhotos, true);
        emit(PhotoUploadSuccess());
      },
    );
  }

  /// Reorder images so the primary image is at index 0
  List<File> _reorderImagesToPrimary() {
    if (images.isEmpty) return [];
    if (primaryIndex == 0) return List<File>.from(images);

    final reordered = <File>[];
    reordered.add(images[primaryIndex]); // Primary at index 0
    for (int i = 0; i < images.length; i++) {
      if (i != primaryIndex) {
        reordered.add(images[i]);
      }
    }
    return reordered;
  }

  /// Mark upload as done without uploading (skip)
  Future<void> skipUpload() async {
    AppLogger.info('Skipping photo upload', tag: 'PHOTO_UPLOAD');
    await _sharedPrefs.save(StorageKeys.uploadedPhotos, true);
    emit(PhotoUploadSuccess());
  }
}
