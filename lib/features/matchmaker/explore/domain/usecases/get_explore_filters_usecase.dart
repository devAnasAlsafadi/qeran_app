import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../../../discovery/domain/entities/discovery_filter_question.dart';
import '../repositories/matchmaker_explore_repository.dart';

/// Fetches the active explore filter questions (reuses the discovery filter
/// entity — identical `/filters` shape).
class GetExploreFiltersUseCase {
  final MatchmakerExploreRepository _repository;
  const GetExploreFiltersUseCase(this._repository);

  Future<Either<Failure, List<DiscoveryFilterQuestion>>> call() =>
      _repository.getFilters();
}
