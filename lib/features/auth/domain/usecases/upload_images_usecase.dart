import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:qeran/core/domain/entities/success_response.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/profile_image_repository.dart';

class UploadImagesUseCase {
  final ProfileImageRepository _repository;

  const UploadImagesUseCase(this._repository);

  Future<Either<Failure, SuccessResponse<dynamic>>> call({
    required List<File> images,
  }) {
    return _repository.uploadImages(images: images);
  }
}
