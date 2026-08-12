import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/my_profile.dart';
import '../repositories/profile_repository.dart';

/// Sets the member's DISPLAY name. Returns the complete updated profile the
/// server responded with, so the caller re-seeds its state from the result
/// instead of issuing a second read.
class UpdateDisplayNameUseCase {
  final ProfileRepository _repository;
  const UpdateDisplayNameUseCase(this._repository);

  Future<Either<Failure, MyProfile>> call(String displayName) =>
      _repository.updateDisplayName(displayName);
}
