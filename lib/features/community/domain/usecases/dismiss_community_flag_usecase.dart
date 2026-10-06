import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/community_author_repository.dart';

/// 5.3 — keep the item: its flag clears for her.
class DismissCommunityFlagUseCase {
  final CommunityAuthorRepository _repository;
  const DismissCommunityFlagUseCase(this._repository);

  Future<Either<Failure, Unit>> call(int flagId) =>
      _repository.dismissFlag(flagId);
}
