import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/photo_view_permission.dart';
import '../../domain/entities/photo_view_session.dart';
import '../../domain/repositories/photo_view_repository.dart';
import '../datasources/photo_view_remote_datasource.dart';

class PhotoViewRepositoryImpl
    with BaseRepository
    implements PhotoViewRepository {
  final PhotoViewRemoteDataSource _dataSource;

  const PhotoViewRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, PhotoViewPermission>> getPermission(
    String targetUserId,
  ) => executeApiCall(
    () async => (await _dataSource.getPermission(targetUserId)).toEntity(),
  );

  @override
  Future<Either<Failure, PhotoViewSession>> beginView(int photoExchangeId) =>
      executeApiCall(
        () async => (await _dataSource.beginView(photoExchangeId)).toEntity(),
      );
}
