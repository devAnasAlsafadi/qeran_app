import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_user_note.dart';
import '../repositories/matchmaker_user_notes_repository.dart';

/// Loads the matchmaker's note about [userId]. Right(null) = no note yet.
class GetUserNoteUseCase {
  final MatchmakerUserNotesRepository _repository;
  const GetUserNoteUseCase(this._repository);

  Future<Either<Failure, MatchmakerUserNote?>> call(String userId) =>
      _repository.getNote(userId);
}
