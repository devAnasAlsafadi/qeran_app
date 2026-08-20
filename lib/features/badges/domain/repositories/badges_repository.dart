import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/badge_counts.dart';

abstract class BadgesRepository {
  /// Current unread counts for the signed-in role. A route that is not
  /// deployed yet resolves to empty counts rather than a failure.
  Future<Either<Failure, BadgeCounts>> getBadges();

  /// Zeroes one tab server-side. Callers treat this as optimistic: the local
  /// count drops immediately and the next [getBadges] settles the truth.
  Future<Either<Failure, Unit>> markTabSeen(String tabKey);
}
