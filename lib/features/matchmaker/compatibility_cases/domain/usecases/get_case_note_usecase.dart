import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/case_note.dart';
import '../repositories/case_note_repository.dart';

/// Loads the matchmaker's note about case [caseId]. Right(null) = no note yet.
class GetCaseNoteUseCase {
  final CaseNoteRepository _repository;
  const GetCaseNoteUseCase(this._repository);

  Future<Either<Failure, CaseNote?>> call(int caseId) =>
      _repository.getNote(caseId);
}
