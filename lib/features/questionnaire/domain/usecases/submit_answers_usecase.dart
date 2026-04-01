import 'package:dartz/dartz.dart';
import 'package:qeran/core/domain/entities/success_response.dart';
import 'package:qeran/core/errors/errors.dart';
import '../repositories/questionnaire_repository.dart';

class SubmitAnswersUseCase {
  final QuestionnaireRepository _repository;

  SubmitAnswersUseCase(this._repository);

  Future<Either<Failure, SuccessResponse>> call({
    required List<Map<String, dynamic>> answers,
  }) {
    return _repository.submitAnswers(answers: answers);
  }
}
