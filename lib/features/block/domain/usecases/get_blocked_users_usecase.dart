import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/blocked_user.dart';
import '../repositories/block_repository.dart';

class GetBlockedUsersUseCase {
  final BlockRepository _repository;
  const GetBlockedUsersUseCase(this._repository);

  Future<Either<Failure, List<BlockedUser>>> call() =>
      _repository.getBlockedUsers();
}
