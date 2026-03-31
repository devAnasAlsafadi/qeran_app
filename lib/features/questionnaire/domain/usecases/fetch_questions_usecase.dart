import 'package:dartz/dartz.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/core/errors/errors.dart';
import '../entities/question_entity.dart';
import '../repositories/questionnaire_repository.dart';

class FetchQuestionsUseCase {
  final QuestionnaireRepository _repository;

  FetchQuestionsUseCase(this._repository);

  Future<Either<Failure, List<QuestionEntity>>> call({required Gender gender}) {
    return _repository.fetchQuestions(gender: gender);
  }
}
