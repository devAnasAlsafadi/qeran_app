import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/case_note.dart';
import '../repositories/case_note_repository.dart';

/// Upserts the matchmaker's note about case [caseId] (content already trimmed
/// by the caller) and returns the saved note.
class SaveCaseNoteUseCase {
  final CaseNoteRepository _repository;
  const SaveCaseNoteUseCase(this._repository);

  Future<Either<Failure, CaseNote>> call({
    required int caseId,
    required String content,
  }) =>
      _repository.saveNote(caseId: caseId, content: content);
}
