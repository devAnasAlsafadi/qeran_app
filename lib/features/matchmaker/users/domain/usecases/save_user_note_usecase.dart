import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_user_note.dart';
import '../repositories/matchmaker_user_notes_repository.dart';

/// Upserts the matchmaker's note about [userId] (content already trimmed by the
/// caller) and returns the saved note.
class SaveUserNoteUseCase {
  final MatchmakerUserNotesRepository _repository;
  const SaveUserNoteUseCase(this._repository);

  Future<Either<Failure, MatchmakerUserNote>> call({
    required String userId,
    required String content,
  }) =>
      _repository.saveNote(userId: userId, content: content);
}
