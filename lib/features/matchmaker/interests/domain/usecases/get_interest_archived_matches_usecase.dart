import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_interest_archive_item.dart';
import '../entities/matchmaker_interest_page.dart';
import '../repositories/matchmaker_interests_repository.dart';

/// Loads the viewed user's archived (closed / cancelled) matches.
class GetInterestArchivedMatchesUseCase {
  final MatchmakerInterestsRepository _repository;
  const GetInterestArchivedMatchesUseCase(this._repository);

  Future<
      Either<Failure,
          MatchmakerInterestPage<List<MatchmakerInterestArchiveItem>>>> call(
    String userId,
  ) =>
      _repository.getArchivedMatches(userId);
}
