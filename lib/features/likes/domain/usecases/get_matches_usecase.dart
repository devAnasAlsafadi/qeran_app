import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/match_card.dart';
import '../repositories/matches_repository.dart';

class GetMatchesUseCase {
  final MatchesRepository _repository;
  const GetMatchesUseCase(this._repository);

  Future<Either<Failure, List<MatchCard>>> call() => _repository.getMatches();
}
