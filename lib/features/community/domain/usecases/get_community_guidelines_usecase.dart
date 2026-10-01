import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/community_guidelines.dart';
import '../repositories/community_repository.dart';

class GetCommunityGuidelinesUseCase {
  final CommunityRepository _repository;
  const GetCommunityGuidelinesUseCase(this._repository);

  Future<Either<Failure, CommunityGuidelines>> call() =>
      _repository.getGuidelines();
}
