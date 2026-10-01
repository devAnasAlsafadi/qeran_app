import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/community_config.dart';
import '../repositories/community_repository.dart';

class GetCommunityConfigUseCase {
  final CommunityRepository _repository;
  const GetCommunityConfigUseCase(this._repository);

  Future<Either<Failure, CommunityConfig>> call() => _repository.getConfig();
}
