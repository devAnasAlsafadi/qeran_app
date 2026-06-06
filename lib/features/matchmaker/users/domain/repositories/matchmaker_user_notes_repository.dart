import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_user_note.dart';

abstract interface class MatchmakerUserNotesRepository {
  /// Right(null) when the user has no note yet.
  Future<Either<Failure, MatchmakerUserNote?>> getNote(String userId);

  Future<Either<Failure, MatchmakerUserNote>> saveNote({
    required String userId,
    required String content,
  });

  Future<Either<Failure, Unit>> deleteNote(String userId);
}
