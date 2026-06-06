import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/matchmaker_user_notes_repository.dart';

/// Deletes the matchmaker's note about [userId] (idempotent server-side).
class DeleteUserNoteUseCase {
  final MatchmakerUserNotesRepository _repository;
  const DeleteUserNoteUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String userId) =>
      _repository.deleteNote(userId);
}
