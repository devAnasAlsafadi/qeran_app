import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/matchmaker_notifications_page.dart';
import '../../domain/repositories/matchmaker_notifications_repository.dart';
import '../datasources/matchmaker_notifications_remote_datasource.dart';

class MatchmakerNotificationsRepositoryImpl
    with BaseRepository
    implements MatchmakerNotificationsRepository {
  final MatchmakerNotificationsRemoteDataSource _dataSource;

  const MatchmakerNotificationsRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, MatchmakerNotificationsPage>> getNotifications({
    required int page,
    required int pageSize,
  }) {
    return executeApiCall(() async {
      final model = await _dataSource.getNotifications(
        page: page,
        pageSize: pageSize,
      );
      return model.toEntity();
    });
  }
}
