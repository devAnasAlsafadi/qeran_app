import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/repositories/change_password_repository.dart';
import '../datasources/change_password_remote_datasource.dart';

class ChangePasswordRepositoryImpl
    with BaseRepository
    implements ChangePasswordRepository {
  final ChangePasswordRemoteDataSource _dataSource;

  const ChangePasswordRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    return executeApiCall(() async {
      await _dataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return unit;
    });
  }
}
