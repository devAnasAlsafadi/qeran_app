import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/like_requests_data.dart';
import '../repositories/likes_repository.dart';

class GetIncomingLikesUseCase {
  final LikesRepository _repository;
  const GetIncomingLikesUseCase(this._repository);

  Future<Either<Failure, LikeRequestsData>> call() =>
      _repository.getIncoming();
}
