import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/my_matchmaker_outcome.dart';
import '../repositories/chat_repository.dart';

class GetMyMatchmakerUseCase {
  final ChatRepository _repository;
  const GetMyMatchmakerUseCase(this._repository);

  Future<Either<Failure, MyMatchmakerOutcome>> call() =>
      _repository.getMyMatchmaker();
}
