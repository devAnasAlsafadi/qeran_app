import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_editable_answers_page.dart';

abstract interface class MatchmakerEditableAnswersRepository {
  Future<Either<Failure, MatchmakerEditableAnswersPage>> getEditableAnswers({
    required String userId,
    required int page,
    required int pageSize,
  });

  /// Returns the server's success text on success (`data` string).
  Future<Either<Failure, String>> updateTextAnswer({
    required String userId,
    required int questionId,
    required String textAnswer,
  });
}
