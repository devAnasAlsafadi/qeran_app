import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../domain/usecases/add_profile_images_usecase.dart';
import '../../../domain/usecases/delete_profile_image_usecase.dart';
import '../../../domain/usecases/get_profile_images_usecase.dart';
import '../../../domain/usecases/set_main_profile_image_usecase.dart';
import 'profile_photos_state.dart';

class ProfilePhotosCubit extends Cubit<ProfilePhotosState>
    with SafeEmit<ProfilePhotosState> {
  ProfilePhotosCubit({
    required GetProfileImagesUseCase getImages,
    required AddProfileImagesUseCase addImages,
    required DeleteProfileImageUseCase deleteImage,
    required SetMainProfileImageUseCase setMain,
  }) : _getImages = getImages,
       _addImages = addImages,
       _deleteImage = deleteImage,
       _setMain = setMain,
       super(const ProfilePhotosState());

  final GetProfileImagesUseCase _getImages;
  final AddProfileImagesUseCase _addImages;
  final DeleteProfileImageUseCase _deleteImage;
  final SetMainProfileImageUseCase _setMain;

  Future<void> load() async {
    emit(state.copyWith(status: ProfilePhotosStatus.loading, clearError: true));
    final result = await _getImages();
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ProfilePhotosStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (images) => emit(
        state.copyWith(
          status: ProfilePhotosStatus.loaded,
          images: images,
          clearError: true,
        ),
      ),
    );
  }

  Future<void> addImage(String path) async {
    if (state.isBusy) return;
    if (!state.canAddMore) {
      _event(ProfilePhotoEvent.maxReached);
      return;
    }
    final validation = _validate(path);
    if (validation != null) {
      _event(ProfilePhotoEvent.validationFailure, errorMessage: validation);
      return;
    }
    emit(state.copyWith(inFlight: ProfilePhotoAction.upload, clearError: true));
    final result = await _addImages([File(path)]);
    await _finishMutation(result, ProfilePhotoEvent.uploaded);
  }

  Future<void> deleteImage(String imageId) async {
    if (state.isBusy) return;
    emit(
      state.copyWith(
        inFlight: ProfilePhotoAction.delete,
        inFlightImageId: imageId,
        clearError: true,
      ),
    );
    final result = await _deleteImage(imageId);
    await _finishMutation(result, ProfilePhotoEvent.deleted);
  }

  Future<void> setMain(String imageId) async {
    if (state.isBusy) return;
    emit(
      state.copyWith(
        inFlight: ProfilePhotoAction.setMain,
        inFlightImageId: imageId,
        clearError: true,
      ),
    );
    final result = await _setMain(imageId);
    await _finishMutation(result, ProfilePhotoEvent.mainChanged);
  }

  Future<void> _finishMutation(
    Either<Failure, Unit> result,
    ProfilePhotoEvent success,
  ) async {
    if (isClosed) return;
    String? failureMessage;
    result.fold<void>((failure) => failureMessage = failure.message, (_) {});
    if (failureMessage != null) {
      emit(
        state.copyWith(
          clearInFlight: true,
          event: ProfilePhotoEvent.actionFailure,
          eventVersion: state.eventVersion + 1,
          errorMessage: failureMessage,
        ),
      );
      return;
    }

    final refreshed = await _getImages();
    if (isClosed) return;
    refreshed.fold(
      (failure) => emit(
        state.copyWith(
          clearInFlight: true,
          event: ProfilePhotoEvent.actionFailure,
          eventVersion: state.eventVersion + 1,
          errorMessage: failure.message,
        ),
      ),
      (images) => emit(
        state.copyWith(
          status: ProfilePhotosStatus.loaded,
          images: images,
          clearInFlight: true,
          event: success,
          eventVersion: state.eventVersion + 1,
          clearError: true,
        ),
      ),
    );
  }

  void _event(ProfilePhotoEvent event, {String? errorMessage}) {
    emit(
      state.copyWith(
        event: event,
        eventVersion: state.eventVersion + 1,
        errorMessage: errorMessage,
        clearError: errorMessage == null,
      ),
    );
  }

  String? _validate(String path) {
    final file = File(path);
    if (!file.existsSync()) return LocaleKeys.auth_photo_validation_not_found;
    final extension = path.contains('.')
        ? path.substring(path.lastIndexOf('.')).toLowerCase()
        : '';
    if (!{'.jpg', '.jpeg', '.png'}.contains(extension)) {
      return LocaleKeys.auth_photo_validation_type;
    }
    try {
      if (file.lengthSync() > 2 * 1024 * 1024) {
        return LocaleKeys.auth_photo_validation_size;
      }
    } catch (_) {
      return LocaleKeys.auth_photo_validation_read_error;
    }
    return null;
  }
}
