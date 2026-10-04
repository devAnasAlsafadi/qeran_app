import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/block/domain/repositories/community_member_blocker.dart';

import '../repositories/community_repository.dart';

/// Blocking a comment's author, through Community (Q3) — what the block
/// cubit calls from a comment's ⋮.
class BlockCommunityMemberUseCase implements CommunityMemberBlocker {
  final CommunityRepository _repository;
  const BlockCommunityMemberUseCase(this._repository);

  @override
  Future<Either<Failure, void>> block(String userId) =>
      _repository.blockMember(userId);
}
