import 'dart:io';

import 'package:dartz/dartz.dart';

import 'package:qeran/core/errors/errors.dart';

import '../repositories/profile_image_repository.dart';

class UploadImagesUseCase {
  final ProfileImageRepository _repository;

  const UploadImagesUseCase(this._repository);

  /// Upload [images] to the server.
  ///
  /// Caller is responsible for placing the primary image at index 0
  /// before invoking this use case.
  Future<Either<Failure, String>> call({required List<File> images}) {
    return _repository.uploadImages(images: images);
  }
}
