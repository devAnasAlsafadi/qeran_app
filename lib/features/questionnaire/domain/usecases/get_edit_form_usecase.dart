import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/editable_category.dart';
import '../repositories/questionnaire_repository.dart';

/// Loads the profile-edit form (`GET /api/questions/edit-form`): every
/// active question for my gender, grouped by category, with my current
/// answers prefilled.
class GetEditFormUseCase {
  final QuestionnaireRepository _repository;

  GetEditFormUseCase(this._repository);

  Future<Either<Failure, List<EditableCategory>>> call() {
    return _repository.fetchEditForm();
  }
}
