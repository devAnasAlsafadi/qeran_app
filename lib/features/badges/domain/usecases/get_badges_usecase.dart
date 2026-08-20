import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/badge_counts.dart';
import '../repositories/badges_repository.dart';

class GetBadgesUseCase {
  const GetBadgesUseCase(this._repository);

  final BadgesRepository _repository;

  Future<Either<Failure, BadgeCounts>> call() => _repository.getBadges();
}
