import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/matchmaker_notifications_repository.dart';

/// Fetches the total notification count (drives the unread-badge heuristic).
class GetNotificationCountUseCase {
  final MatchmakerNotificationsRepository _repository;
  const GetNotificationCountUseCase(this._repository);

  Future<Either<Failure, int>> call() => _repository.getCount();
}
