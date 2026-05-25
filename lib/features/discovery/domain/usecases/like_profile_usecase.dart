import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/like_outcome.dart';
import '../repositories/discovery_repository.dart';

class LikeProfileUseCase {
  final DiscoveryRepository _repository;

  const LikeProfileUseCase(this._repository);

  Future<Either<Failure, LikeOutcome>> call(String profileId) {
    return _repository.likeProfile(profileId);
  }
}
