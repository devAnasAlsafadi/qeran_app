import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/my_profile.dart';
import '../repositories/profile_repository.dart';

class GetMyProfileUseCase {
  final ProfileRepository _repository;
  const GetMyProfileUseCase(this._repository);

  Future<Either<Failure, MyProfile>> call() => _repository.getMyProfile();
}
