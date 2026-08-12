import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/profile_repository.dart';

class DeleteProfileImageUseCase {
  const DeleteProfileImageUseCase(this._repository);
  final ProfileRepository _repository;

  Future<Either<Failure, Unit>> call(String imageId) =>
      _repository.deleteProfileImage(imageId);
}
