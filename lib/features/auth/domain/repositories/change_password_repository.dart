import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

/// Changes the signed-in user's password via the shared auth endpoint.
abstract interface class ChangePasswordRepository {
  Future<Either<Failure, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });
}
