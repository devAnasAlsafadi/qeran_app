import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/block_repository.dart';

class UnblockUserUseCase {
  final BlockRepository _repository;
  const UnblockUserUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String targetUserId) =>
      _repository.unblockUser(targetUserId);
}
