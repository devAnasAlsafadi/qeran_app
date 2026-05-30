import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/matchmaker_dashboard_stats.dart';
import '../../domain/repositories/matchmaker_dashboard_repository.dart';
import '../datasources/matchmaker_dashboard_remote_datasource.dart';

class MatchmakerDashboardRepositoryImpl
    with BaseRepository
    implements MatchmakerDashboardRepository {
  final MatchmakerDashboardRemoteDataSource _dataSource;

  const MatchmakerDashboardRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, MatchmakerDashboardStats>> getDashboard() {
    return executeApiCall(() async {
      final model = await _dataSource.getDashboard();
      return model.toEntity();
    });
  }
}
