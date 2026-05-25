import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/profile_fetch_outcome.dart';
import '../repositories/profile_repository.dart';

class GetProfileByIdUseCase {
  final ProfileRepository _repository;
  const GetProfileByIdUseCase(this._repository);

  Future<Either<Failure, ProfileFetchOutcome>> call(String userId) =>
      _repository.getProfileById(userId);
}
