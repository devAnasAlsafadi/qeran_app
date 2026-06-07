import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_interest_enums.dart';
import '../entities/matchmaker_interest_page.dart';
import '../entities/matchmaker_like_activity.dart';
import '../repositories/matchmaker_interests_repository.dart';

/// Loads one of the viewed user's like lists (outgoing / incoming) for the
/// matchmaker mirror.
class GetInterestLikesUseCase {
  final MatchmakerInterestsRepository _repository;
  const GetInterestLikesUseCase(this._repository);

  Future<Either<Failure, MatchmakerInterestPage<MatchmakerLikeActivity>>> call(
    String userId, {
    required MatchmakerLikeDirection direction,
  }) =>
      _repository.getLikes(userId, direction);
}
