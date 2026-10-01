import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/community_repository.dart';

class AcceptCommunityGuidelinesUseCase {
  final CommunityRepository _repository;
  const AcceptCommunityGuidelinesUseCase(this._repository);

  Future<Either<Failure, Unit>> call(int version) =>
      _repository.acceptGuidelines(version);
}
