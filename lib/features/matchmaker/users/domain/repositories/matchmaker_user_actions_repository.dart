import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

/// Review actions on a single user's profile. Each returns the server's
/// success text (the `data` string) on success, or maps to a [Failure].
abstract interface class MatchmakerUserActionsRepository {
  Future<Either<Failure, String>> approve(String userId);

  Future<Either<Failure, String>> reject({
    required String userId,
    required String reason,
  });

  Future<Either<Failure, String>> requestImage(String userId);
}
