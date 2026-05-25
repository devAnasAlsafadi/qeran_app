import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/current_subscription.dart';
import '../repositories/subscriptions_repository.dart';

class GetCurrentSubscriptionUseCase {
  final SubscriptionsRepository _repository;
  const GetCurrentSubscriptionUseCase(this._repository);

  Future<Either<Failure, CurrentSubscription?>> call() =>
      _repository.getCurrent();
}
