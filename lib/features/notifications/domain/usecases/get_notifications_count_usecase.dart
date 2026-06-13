import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/notifications_repository.dart';

/// Fetches the total notification count. Reserved for the deferred local
/// unread-badge heuristic (step 5) — wired but not yet consumed by any UI.
class GetNotificationsCountUseCase {
  final NotificationsRepository _repository;
  const GetNotificationsCountUseCase(this._repository);

  Future<Either<Failure, int>> call() => _repository.getCount();
}
