import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/current_subscription.dart';
import '../../domain/entities/discount_validation.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/repositories/subscriptions_repository.dart';
import '../datasources/subscriptions_remote_datasource.dart';

class SubscriptionsRepositoryImpl
    with BaseRepository
    implements SubscriptionsRepository {
  final SubscriptionsRemoteDataSource _dataSource;

  const SubscriptionsRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<SubscriptionPlan>>> getPlans() {
    return executeApiCall(() async {
      final models = await _dataSource.getPlans();
      return models.map((m) => m.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, CurrentSubscription?>> getCurrent() {
    return executeApiCall(() async {
      final model = await _dataSource.getCurrent();
      return model?.toEntity();
    });
  }

  @override
  Future<Either<Failure, DiscountValidation>> validateDiscount({
    required String code,
    required int pricingId,
  }) {
    return executeApiCall(() async {
      final model = await _dataSource.validateDiscount(
        code: code,
        pricingId: pricingId,
      );
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, CurrentSubscription>> subscribe({
    required int pricingId,
    String? discountCode,
  }) {
    return executeApiCall(() async {
      final model = await _dataSource.subscribe(
        pricingId: pricingId,
        discountCode: discountCode,
      );
      return model.toEntity();
    });
  }
}
