import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/notifications_page.dart';

abstract interface class NotificationsRepository {
  /// Fetches one page of the inbox. Left on transport / auth failure.
  Future<Either<Failure, NotificationsPage>> getNotifications({
    required int page,
    required int pageSize,
  });
}
