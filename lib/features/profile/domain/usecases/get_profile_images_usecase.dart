import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/profile_image.dart';
import '../repositories/profile_repository.dart';

class GetProfileImagesUseCase {
  const GetProfileImagesUseCase(this._repository);
  final ProfileRepository _repository;

  Future<Either<Failure, List<OwnerImage>>> call() =>
      _repository.getProfileImages();
}
