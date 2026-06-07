import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_notifications_page.dart';

abstract interface class MatchmakerNotificationsRepository {
  /// Fetches one page of the inbox. Left on transport / auth failure.
  Future<Either<Failure, MatchmakerNotificationsPage>> getNotifications({
    required int page,
    required int pageSize,
  });

  /// Total notification count (not unread). Left on failure.
  Future<Either<Failure, int>> getCount();
}
