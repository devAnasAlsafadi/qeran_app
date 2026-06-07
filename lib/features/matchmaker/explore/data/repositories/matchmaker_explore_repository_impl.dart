import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../../../discovery/domain/entities/discovery_filter_question.dart';
import '../../domain/entities/matchmaker_explore_page.dart';
import '../../domain/repositories/matchmaker_explore_repository.dart';
import '../datasources/matchmaker_explore_remote_datasource.dart';

class MatchmakerExploreRepositoryImpl
    with BaseRepository
    implements MatchmakerExploreRepository {
  final MatchmakerExploreRemoteDataSource _dataSource;

  const MatchmakerExploreRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, MatchmakerExplorePage>> getExplore({
    required int page,
    required int pageSize,
    String? search,
    Gender? gender,
    Map<int, List<String>> questionFilters = const {},
  }) {
    return executeApiCall(() async {
      final model = await _dataSource.getExplore(
        page: page,
        pageSize: pageSize,
        search: search,
        gender: gender,
        questionFilters: questionFilters,
      );
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, List<DiscoveryFilterQuestion>>> getFilters() {
    return executeApiCall(() async {
      final models = await _dataSource.getFilters();
      return models.map((m) => m.toEntity()).toList(growable: false);
    });
  }
}
