import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_user_profile.dart';
import '../repositories/matchmaker_user_profile_repository.dart';

class FetchMatchmakerUserProfileUseCase {
  final MatchmakerUserProfileRepository _repository;
  const FetchMatchmakerUserProfileUseCase(this._repository);

  Future<Either<Failure, MatchmakerUserProfile>> call(String userId) =>
      _repository.getUserProfile(userId);
}
