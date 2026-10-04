import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

/// Blocks the author of a Community comment. Community provides it (Q3): it
/// goes through Community's datasource, so the dev-flag mock's made-up ids
/// can never reach the real `POST block`.
abstract interface class CommunityMemberBlocker {
  Future<Either<Failure, void>> block(String userId);
}
