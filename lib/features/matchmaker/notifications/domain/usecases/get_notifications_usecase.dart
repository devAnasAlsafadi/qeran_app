import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_notifications_page.dart';
import '../repositories/matchmaker_notifications_repository.dart';

/// Fetches one page of the matchmaker's notification inbox.
class GetNotificationsUseCase {
  final MatchmakerNotificationsRepository _repository;
  const GetNotificationsUseCase(this._repository);

  Future<Either<Failure, MatchmakerNotificationsPage>> call({
    required int page,
    required int pageSize,
  }) =>
      _repository.getNotifications(page: page, pageSize: pageSize);
}
