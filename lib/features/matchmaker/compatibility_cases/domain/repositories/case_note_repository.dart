import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/case_note.dart';

abstract interface class CaseNoteRepository {
  /// Right(null) when the case has no note yet.
  Future<Either<Failure, CaseNote?>> getNote(int caseId);

  Future<Either<Failure, CaseNote>> saveNote({
    required int caseId,
    required String content,
  });

  Future<Either<Failure, Unit>> deleteNote(int caseId);
}
