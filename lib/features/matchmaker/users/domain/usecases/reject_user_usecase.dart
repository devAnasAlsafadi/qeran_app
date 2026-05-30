import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/matchmaker_user_actions_repository.dart';

class RejectUserUseCase {
  final MatchmakerUserActionsRepository _repository;
  const RejectUserUseCase(this._repository);

  /// [reason] is sent verbatim — the backend forwards it to the user as a
  /// chat message with no prefix, so the caller writes the complete text.
  Future<Either<Failure, String>> call({
    required String userId,
    required String reason,
  }) =>
      _repository.reject(userId: userId, reason: reason);
}
