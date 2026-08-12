import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/profile_repository.dart';

class AddProfileImagesUseCase {
  const AddProfileImagesUseCase(this._repository);
  final ProfileRepository _repository;

  Future<Either<Failure, Unit>> call(List<File> images) =>
      _repository.addProfileImages(images);
}
