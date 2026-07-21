import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/current_subscription.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/validate_code_response.dart';
import '../../domain/repositories/subscriptions_repository.dart';
import '../datasources/subscriptions_remote_datasource.dart';
import '../models/validate_code_request.dart';

class SubscriptionsRepositoryImpl
    with BaseRepository
    implements SubscriptionsRepository {
  final SubscriptionsRemoteDataSource _dataSource;

  // Plans are dashboard-defined and effectively static within a session, so
  // the first successful fetch is cached in memory for the app's lifetime.
  // `_inflightPlans` coalesces concurrent callers onto a single request;
  // `_cachedPlans` then serves every later call without touching the network.
  // (No mutable state can live behind a const constructor — hence non-const.)
  List<SubscriptionPlan>? _cachedPlans;
  Future<Either<Failure, List<SubscriptionPlan>>>? _inflightPlans;

  SubscriptionsRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<SubscriptionPlan>>> getPlans() {
    final cached = _cachedPlans;
    if (cached != null) return Future.value(Right(cached));

    final existing = _inflightPlans;
    if (existing != null) return existing;

    final task = executeApiCall(() async {
      final models = await _dataSource.getPlans();
      return models.map((m) => m.toEntity()).toList();
    }).then((result) {
      // Cache only on success — a failure must not poison the cache; the next
      // call retries.
      result.fold((_) {}, (plans) {
        _cachedPlans = plans;
      });
      return result;
    });

    _inflightPlans = task;
    task.whenComplete(() => _inflightPlans = null);
    return task;
  }

  /// Drops the cached plans so the next [getPlans] refetches. Defensive hook
  /// for a future plans-mutation event; not called anywhere yet.
  void invalidatePlansCache() => _cachedPlans = null;

  @override
  Future<Either<Failure, CurrentSubscription?>> getCurrent() {
    return executeApiCall(() async {
      final model = await _dataSource.getCurrent();
      return model?.toEntity();
    });
  }

  @override
  Future<Either<Failure, CurrentSubscription>> subscribe({
    required int pricingId,
    String? discountCode,
  }) async {
    // NOT executeApiCall: subscribe must PRESERVE the backend `errorCode`
    // (FREE_PLAN_ALREADY_USED / PROFILE_NOT_APPROVED) as a CodedServerFailure so
    // the purchase flow can treat them as benign / "under review" rather than a
    // generic failure. `base_repository` intentionally collapses errorCode.
    try {
      final model = await _dataSource.subscribe(
        pricingId: pricingId,
        discountCode: discountCode,
      );
      return Right(model.toEntity());
    } on OfflineException {
      return const Left(OfflineFailure());
    } on CodedServerException catch (e) {
      return Left(CodedServerFailure(
        message: e.message,
        errorCode: e.errorCode,
        statusCode: e.statusCode,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure(message: LocaleKeys.errors_unexpected));
    }
  }

  @override
  Future<Either<Failure, ValidateCodeResponse>> validateCode({
    required String code,
    required String productId,
    required String platform,
  }) {
    return executeApiCall(() async {
      final model = await _dataSource.validateCode(
        ValidateCodeRequest(
          code: code,
          productId: productId,
          platform: platform,
        ),
      );
      return model.toEntity();
    });
  }
}
