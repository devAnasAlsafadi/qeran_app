import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/photo_exchange_outcome.dart';
import '../repositories/matches_repository.dart';

class RejectPhotoExchangeUseCase {
  final MatchesRepository _repository;
  const RejectPhotoExchangeUseCase(this._repository);

  Future<Either<Failure, PhotoExchangeRespondOutcome>> call(int requestId) =>
      _repository.rejectPhotoExchange(requestId);
}
