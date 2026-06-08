import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/repositories/matchmaker_editable_answers_repository.dart';
import '../datasources/matchmaker_editable_answers_remote_datasource.dart';

class MatchmakerEditableAnswersRepositoryImpl
    with BaseRepository
    implements MatchmakerEditableAnswersRepository {
  final MatchmakerEditableAnswersRemoteDataSource _dataSource;

  const MatchmakerEditableAnswersRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, String>> updateTextAnswer({
    required String userId,
    required int questionId,
    required String textAnswer,
  }) {
    return executeApiCall(
      () => _dataSource.updateTextAnswer(
        userId: userId,
        questionId: questionId,
        textAnswer: textAnswer,
      ),
    );
  }
}
