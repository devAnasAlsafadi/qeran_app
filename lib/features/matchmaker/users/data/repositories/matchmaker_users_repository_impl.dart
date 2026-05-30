import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/matchmaker_users_list.dart';
import '../../domain/entities/matchmaker_users_page.dart';
import '../../domain/repositories/matchmaker_users_repository.dart';
import '../datasources/matchmaker_users_remote_datasource.dart';

class MatchmakerUsersRepositoryImpl
    with BaseRepository
    implements MatchmakerUsersRepository {
  final MatchmakerUsersRemoteDataSource _dataSource;

  const MatchmakerUsersRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, MatchmakerUsersPage>> getUsers({
    required MatchmakerUsersList list,
    required int page,
    required int pageSize,
  }) {
    return executeApiCall(() async {
      final model = await _dataSource.getUsers(
        list: list,
        page: page,
        pageSize: pageSize,
      );
      return model.toEntity();
    });
  }
}
