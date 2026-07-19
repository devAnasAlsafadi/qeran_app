import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/blocked_user.dart';

abstract interface class BlockRepository {
  /// `POST /api/block {targetUserId}` — full teardown server-side. On a status:0
  /// rejection returns a [CodedServerFailure] carrying the backend `errorCode`.
  Future<Either<Failure, Unit>> blockUser(String targetUserId);

  /// `DELETE /api/block/{targetUserId}` — unblock.
  Future<Either<Failure, Unit>> unblockUser(String targetUserId);

  /// `GET /api/block` — the list of users this account has blocked.
  Future<Either<Failure, List<BlockedUser>>> getBlockedUsers();
}
