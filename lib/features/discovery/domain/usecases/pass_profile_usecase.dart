import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/discovery_repository.dart';

class PassProfileUseCase {
  final DiscoveryRepository _repository;

  const PassProfileUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String profileId) {
    return _repository.passProfile(profileId);
  }
}
