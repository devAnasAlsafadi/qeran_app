import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/domain/entities/success_response.dart';
import '../../domain/entities/editable_category.dart';
import '../../domain/entities/question_entity.dart';
import '../../domain/repositories/questionnaire_repository.dart';
import '../datasources/questionnaire_remote_datasource.dart';

class QuestionnaireRepositoryImpl
    with BaseRepository
    implements QuestionnaireRepository {
  final QuestionnaireRemoteDataSource _dataSource;

  // The edit-form schema is effectively static within a session, so the first
  // successful fetch is cached in memory for the app's lifetime.
  // `_inflightEditForm` coalesces concurrent callers onto a single request;
  // `_cachedEditForm` then serves later calls without touching the network. It
  // is invalidated the moment the user submits new answers (see submitAnswers).
  // (No mutable state can live behind a const constructor — hence non-const.)
  List<EditableCategory>? _cachedEditForm;
  Future<Either<Failure, List<EditableCategory>>>? _inflightEditForm;

  QuestionnaireRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<QuestionEntity>>> fetchQuestions({
    required Gender gender,
  }) {
    return executeApiCall(() async {
      final models = await _dataSource.fetchQuestions(gender: gender);
      return models.map((m) => m.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, List<EditableCategory>>> fetchEditForm() {
    final cached = _cachedEditForm;
    if (cached != null) return Future.value(Right(cached));

    final existing = _inflightEditForm;
    if (existing != null) return existing;

    final task = executeApiCall(() async {
      final models = await _dataSource.fetchEditForm();
      return models.map((m) => m.toEntity()).toList();
    }).then((result) {
      // Cache only on success — a failure must not poison the cache; the next
      // call retries.
      result.fold((_) {}, (form) {
        _cachedEditForm = form;
      });
      return result;
    });

    _inflightEditForm = task;
    task.whenComplete(() => _inflightEditForm = null);
    return task;
  }

  /// Drops the cached edit-form so the next [fetchEditForm] refetches. Called
  /// on a successful [submitAnswers] (the user just changed their answers).
  void invalidateEditFormCache() => _cachedEditForm = null;

  @override
  Future<Either<Failure, SuccessResponse>> submitAnswers({
    required List<Map<String, dynamic>> answers,
  }) {
    return executeApiCall<SuccessResponse>(() async {
      final successResponse = await _dataSource.submitAnswers(answers: answers);

      return successResponse;
    }).then((result) {
      // Invalidate BEFORE the future resolves so a reopen right after a
      // successful submit refetches fresh answers. Failures leave the cache.
      result.fold((_) {}, (_) => invalidateEditFormCache());
      return result;
    });
  }
}
