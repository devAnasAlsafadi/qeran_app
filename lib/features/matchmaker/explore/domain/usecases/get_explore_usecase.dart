import 'package:dartz/dartz.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_explore_page.dart';
import '../repositories/matchmaker_explore_repository.dart';

/// Fetches one page of explore results for the active search / gender /
/// question filters.
class GetExploreUseCase {
  final MatchmakerExploreRepository _repository;
  const GetExploreUseCase(this._repository);

  Future<Either<Failure, MatchmakerExplorePage>> call({
    required int page,
    required int pageSize,
    String? search,
    Gender? gender,
    Map<int, List<String>> questionFilters = const {},
    Map<int, double> rangeFrom = const {},
    Map<int, double> rangeTo = const {},
  }) =>
      _repository.getExplore(
        page: page,
        pageSize: pageSize,
        search: search,
        gender: gender,
        questionFilters: questionFilters,
        rangeFrom: rangeFrom,
        rangeTo: rangeTo,
      );
}
