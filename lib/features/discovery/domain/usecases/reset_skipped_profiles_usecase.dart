import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/discovery_repository.dart';

/// Puts every profile the user skipped back into the deck.
///
/// The `int` on the right is the number restored, and `0` carries meaning:
/// the reset succeeded but there was nothing to undo. Callers must branch on
/// it rather than treating any `Right` as "the deck changed".
class ResetSkippedProfilesUseCase {
  final DiscoveryRepository _repository;

  const ResetSkippedProfilesUseCase(this._repository);

  Future<Either<Failure, int>> call() {
    return _repository.resetSkippedProfiles();
  }
}
