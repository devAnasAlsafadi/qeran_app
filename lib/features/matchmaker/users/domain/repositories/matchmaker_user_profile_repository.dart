import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_user_profile.dart';

abstract interface class MatchmakerUserProfileRepository {
  Future<Either<Failure, MatchmakerUserProfile>> getUserProfile(String userId);
}
