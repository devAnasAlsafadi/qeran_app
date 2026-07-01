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

  // Filters are read-only reference data, effectively static within a session,
  // so the first successful fetch is cached in memory for the app's lifetime.
  // `_inflightFilters` coalesces concurrent callers onto a single request;
  // `_cachedFilters` then serves later calls without touching the network.
  // (No mutable state can live behind a const constructor — hence non-const.)
  List<DiscoveryFilterQuestion>? _cachedFilters;
  Future<Either<Failure, List<DiscoveryFilterQuestion>>>? _inflightFilters;

  MatchmakerExploreRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, MatchmakerExplorePage>> getExplore({
    required int page,
    required int pageSize,
    String? search,
    Gender? gender,
    Map<int, List<String>> questionFilters = const {},
    Map<int, double> rangeFrom = const {},
    Map<int, double> rangeTo = const {},
  }) {
    return executeApiCall(() async {
      final model = await _dataSource.getExplore(
        page: page,
        pageSize: pageSize,
        search: search,
        gender: gender,
        questionFilters: questionFilters,
        rangeFrom: rangeFrom,
        rangeTo: rangeTo,
      );
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, List<DiscoveryFilterQuestion>>> getFilters() {
    final cached = _cachedFilters;
    if (cached != null) return Future.value(Right(cached));

    final existing = _inflightFilters;
    if (existing != null) return existing;

    final task = executeApiCall(() async {
      final models = await _dataSource.getFilters();
      return models.map((m) => m.toEntity()).toList(growable: false);
    }).then((result) {
      // Cache only on success — a failure must not poison the cache; the next
      // call retries.
      result.fold((_) {}, (filters) {
        _cachedFilters = filters;
      });
      return result;
    });

    _inflightFilters = task;
    task.whenComplete(() => _inflightFilters = null);
    return task;
  }

  /// Drops the cached filters so the next [getFilters] refetches. Defensive
  /// hook for a future filters-mutation event; not called anywhere yet.
  void invalidateFiltersCache() => _cachedFilters = null;
}
