import 'package:dartz/dartz.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/domain/entities/success_response.dart';
import '../entities/question_entity.dart';

abstract interface class QuestionnaireRepository {
  Future<Either<Failure, List<QuestionEntity>>> fetchQuestions({
    required Gender gender,
  });

  Future<Either<Failure, SuccessResponse>> submitAnswers({
    required List<Map<String, dynamic>> answers,
  });
}
