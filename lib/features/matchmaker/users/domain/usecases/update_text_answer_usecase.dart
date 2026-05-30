import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/matchmaker_editable_answers_repository.dart';

class UpdateTextAnswerUseCase {
  final MatchmakerEditableAnswersRepository _repository;
  const UpdateTextAnswerUseCase(this._repository);

  Future<Either<Failure, String>> call({
    required String userId,
    required int questionId,
    required String textAnswer,
  }) =>
      _repository.updateTextAnswer(
        userId: userId,
        questionId: questionId,
        textAnswer: textAnswer,
      );
}
