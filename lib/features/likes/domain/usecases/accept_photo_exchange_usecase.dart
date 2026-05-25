import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/photo_exchange_outcome.dart';
import '../repositories/matches_repository.dart';

class AcceptPhotoExchangeUseCase {
  final MatchesRepository _repository;
  const AcceptPhotoExchangeUseCase(this._repository);

  Future<Either<Failure, PhotoExchangeRespondOutcome>> call(int requestId) =>
      _repository.acceptPhotoExchange(requestId);
}
