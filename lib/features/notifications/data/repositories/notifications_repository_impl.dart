import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/notifications_page.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl
    with BaseRepository
    implements NotificationsRepository {
  final NotificationsRemoteDataSource _dataSource;

  const NotificationsRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, NotificationsPage>> getNotifications({
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

  @override
  Future<Either<Failure, int>> getCount() =>
      executeApiCall(() => _dataSource.getCount());
}
