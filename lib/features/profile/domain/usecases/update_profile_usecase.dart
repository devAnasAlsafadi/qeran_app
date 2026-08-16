import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/my_profile.dart';
import '../repositories/profile_repository.dart';

/// Sets the member's names. Returns the complete updated profile the server
/// responded with, so the caller re-seeds its state from the result instead of
/// issuing a second read.
///
/// [displayName] is required on every call. [realName] null leaves the stored
/// value untouched; `''` clears it.
class UpdateProfileUseCase {
  final ProfileRepository _repository;
  const UpdateProfileUseCase(this._repository);

  Future<Either<Failure, MyProfile>> call({
    required String displayName,
    String? realName,
  }) => _repository.updateProfile(
    displayName: displayName,
    realName: realName,
  );
}
