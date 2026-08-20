import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/badges_repository.dart';

class MarkTabSeenUseCase {
  const MarkTabSeenUseCase(this._repository);

  final BadgesRepository _repository;

  Future<Either<Failure, Unit>> call(String tabKey) =>
      _repository.markTabSeen(tabKey);
}
