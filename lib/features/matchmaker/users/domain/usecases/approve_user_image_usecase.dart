import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/matchmaker_user_actions_repository.dart';

class ApproveUserImageUseCase {
  const ApproveUserImageUseCase(this._repository);
  final MatchmakerUserActionsRepository _repository;

  Future<Either<Failure, String>> call({
    required String userId,
    required String imageId,
  }) => _repository.approveImage(userId: userId, imageId: imageId);
}
