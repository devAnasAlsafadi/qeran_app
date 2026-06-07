import 'package:dartz/dartz.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../../../discovery/domain/entities/discovery_filter_question.dart';
import '../entities/matchmaker_explore_page.dart';

abstract interface class MatchmakerExploreRepository {
  /// Fetches one page of explore results for the given filters. Left on
  /// transport / auth failure, Right with the parsed page on success.
  Future<Either<Failure, MatchmakerExplorePage>> getExplore({
    required int page,
    required int pageSize,
    String? search,
    Gender? gender,
    Map<int, List<String>> questionFilters,
  });

  /// Fetches the active explore filter questions (reuses the discovery
  /// filter entity — same `/filters` shape).
  Future<Either<Failure, List<DiscoveryFilterQuestion>>> getFilters();
}
