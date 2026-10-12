import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

/// Changes the signed-in user's password via the shared auth endpoint; the
/// success value is the new token it answers with, if any.
abstract interface class ChangePasswordRepository {
  Future<Either<Failure, String?>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });
}
