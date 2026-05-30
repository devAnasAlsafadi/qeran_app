import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_editable_answers_page.dart';
import '../repositories/matchmaker_editable_answers_repository.dart';

class GetEditableAnswersUseCase {
  final MatchmakerEditableAnswersRepository _repository;
  const GetEditableAnswersUseCase(this._repository);

  Future<Either<Failure, MatchmakerEditableAnswersPage>> call({
    required String userId,
    required int page,
    required int pageSize,
  }) =>
      _repository.getEditableAnswers(
        userId: userId,
        page: page,
        pageSize: pageSize,
      );
}
