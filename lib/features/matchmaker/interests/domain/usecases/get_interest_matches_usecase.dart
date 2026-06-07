import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_interest_match.dart';
import '../entities/matchmaker_interest_page.dart';
import '../repositories/matchmaker_interests_repository.dart';

/// Loads the viewed user's active matches for the matchmaker mirror.
class GetInterestMatchesUseCase {
  final MatchmakerInterestsRepository _repository;
  const GetInterestMatchesUseCase(this._repository);

  Future<Either<Failure, MatchmakerInterestPage<List<MatchmakerInterestMatch>>>>
      call(String userId) => _repository.getMatches(userId);
}
