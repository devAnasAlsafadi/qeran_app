import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/notifications_page.dart';
import '../repositories/notifications_repository.dart';

/// Fetches one page of the user's notification inbox.
class GetNotificationsUseCase {
  final NotificationsRepository _repository;
  const GetNotificationsUseCase(this._repository);

  Future<Either<Failure, NotificationsPage>> call({
    required int page,
    required int pageSize,
  }) =>
      _repository.getNotifications(page: page, pageSize: pageSize);
}
