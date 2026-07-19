import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/block_repository.dart';

class BlockUserUseCase {
  final BlockRepository _repository;
  const BlockUserUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String targetUserId) =>
      _repository.blockUser(targetUserId);
}
