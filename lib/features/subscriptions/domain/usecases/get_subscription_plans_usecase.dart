import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/subscription_plan.dart';
import '../repositories/subscriptions_repository.dart';

class GetSubscriptionPlansUseCase {
  final SubscriptionsRepository _repository;
  const GetSubscriptionPlansUseCase(this._repository);

  Future<Either<Failure, List<SubscriptionPlan>>> call() =>
      _repository.getPlans();
}
