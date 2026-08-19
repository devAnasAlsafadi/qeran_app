import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/profile_image.dart';
import '../repositories/profile_repository.dart';

class AddProfileImagesUseCase {
  const AddProfileImagesUseCase(this._repository);
  final ProfileRepository _repository;

  /// Resolves to the images this upload created, in submission order.
  Future<Either<Failure, List<OwnerImage>>> call(List<File> images) =>
      _repository.addProfileImages(images);
}
