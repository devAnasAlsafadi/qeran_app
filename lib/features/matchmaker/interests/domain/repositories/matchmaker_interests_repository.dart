import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_interest_archive_item.dart';
import '../entities/matchmaker_interest_enums.dart';
import '../entities/matchmaker_interest_match.dart';
import '../entities/matchmaker_interest_page.dart';
import '../entities/matchmaker_like_activity.dart';

abstract interface class MatchmakerInterestsRepository {
  Future<Either<Failure, MatchmakerInterestPage<MatchmakerLikeActivity>>>
      getLikes(String userId, MatchmakerLikeDirection direction);

  Future<Either<Failure, MatchmakerInterestPage<List<MatchmakerInterestMatch>>>>
      getMatches(String userId);

  Future<
          Either<Failure,
              MatchmakerInterestPage<List<MatchmakerInterestArchiveItem>>>>
      getArchivedMatches(String userId);
}
