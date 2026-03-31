import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/core/errors/errors.dart';
import '../../domain/entities/question_entity.dart';
import '../../domain/repositories/questionnaire_repository.dart';
import '../datasources/questionnaire_remote_datasource.dart';

class QuestionnaireRepositoryImpl
    with BaseRepository
    implements QuestionnaireRepository {
  final QuestionnaireRemoteDataSource _dataSource;

  const QuestionnaireRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<QuestionEntity>>> fetchQuestions({
    required Gender gender,
  }) {
    return executeApiCall(() async {
      final models = await _dataSource.fetchQuestions(gender: gender);
      return models.map((m) => m.toEntity()).toList();
    });
  }
}
