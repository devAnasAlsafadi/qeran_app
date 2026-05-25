import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/like_action_outcome.dart';
import '../repositories/likes_repository.dart';

class RejectLikeUseCase {
  final LikesRepository _repository;
  const RejectLikeUseCase(this._repository);

  Future<Either<Failure, LikeActionOutcome>> call(int likeRequestId) =>
      _repository.rejectLike(likeRequestId);
}
