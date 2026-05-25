import 'package:dartz/dartz.dart';

import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/discovery_filter_question.dart';
import '../../domain/entities/discovery_page.dart';
import '../../domain/entities/like_outcome.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../datasources/discovery_remote_datasource.dart';

class DiscoveryRepositoryImpl
    with BaseRepository
    implements DiscoveryRepository {
  final DiscoveryRemoteDataSource _dataSource;

  const DiscoveryRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, DiscoveryPage>> fetchPage({
    int page = 1,
    int pageSize = 10,
    Map<String, String>? filterParams,
  }) {
    return executeApiCall(() async {
      final model = await _dataSource.fetchPage(
        page: page,
        pageSize: pageSize,
        filterParams: filterParams,
      );
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, LikeOutcome>> likeProfile(String profileId) {
    // Semantic outcomes (paywall, already-pending, gender mismatch,
    // user gone) are returned by the data source on the Right side.
    // Anything else — unrecognised server message or transport error —
    // becomes Left(Failure) via `executeApiCall`.
    return executeApiCall(() => _dataSource.likeProfile(profileId));
  }

  @override
  Future<Either<Failure, Unit>> passProfile(String profileId) {
    // Hits `POST /api/discovery/skip/{id}`. The "pass" name stays in
    // the UI / cubit layer for now (per the integration plan §11) —
    // only the data-layer binding switches to the real backend route.
    return executeApiCall(() async {
      await _dataSource.skipProfile(profileId);
      return unit;
    });
  }

  @override
  Future<Either<Failure, List<DiscoveryFilterQuestion>>> getFilters() {
    return executeApiCall(() async {
      final models = await _dataSource.fetchFilters();
      return models.map((m) => m.toEntity()).toList();
    });
  }
}
