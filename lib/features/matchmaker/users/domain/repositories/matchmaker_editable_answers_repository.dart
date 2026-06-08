import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

abstract interface class MatchmakerEditableAnswersRepository {
  /// Returns the server's success text on success (`data` string).
  Future<Either<Failure, String>> updateTextAnswer({
    required String userId,
    required int questionId,
    required String textAnswer,
  });
}
