import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/case_note_repository.dart';

/// Deletes the matchmaker's note about case [caseId] (idempotent server-side).
class DeleteCaseNoteUseCase {
  final CaseNoteRepository _repository;
  const DeleteCaseNoteUseCase(this._repository);

  Future<Either<Failure, Unit>> call(int caseId) =>
      _repository.deleteNote(caseId);
}
