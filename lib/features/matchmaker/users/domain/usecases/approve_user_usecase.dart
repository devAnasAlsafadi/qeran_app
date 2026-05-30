import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/matchmaker_user_actions_repository.dart';

class ApproveUserUseCase {
  final MatchmakerUserActionsRepository _repository;
  const ApproveUserUseCase(this._repository);

  Future<Either<Failure, String>> call(String userId) =>
      _repository.approve(userId);
}
