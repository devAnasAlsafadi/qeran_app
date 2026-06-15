import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/subscription_plan.dart';
import '../repositories/matchmaker_users_repository.dart';

/// Fetches the dynamic subscription-plan list for the مشتركون filter rail.
class FetchSubscriptionPlansUseCase {
  final MatchmakerUsersRepository _repository;
  const FetchSubscriptionPlansUseCase(this._repository);

  Future<Either<Failure, List<SubscriptionPlan>>> call() =>
      _repository.getSubscriptionPlans();
}
