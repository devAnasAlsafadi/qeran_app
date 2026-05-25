import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/photo_exchange_outcome.dart';
import '../repositories/matches_repository.dart';

class RequestPhotoExchangeUseCase {
  final MatchesRepository _repository;
  const RequestPhotoExchangeUseCase(this._repository);

  Future<Either<Failure, PhotoExchangeRequestOutcome>> call(
    int likeRequestId,
  ) =>
      _repository.requestPhotoExchange(likeRequestId);
}
