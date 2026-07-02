import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../models/current_subscription_model.dart';
import '../models/subscription_plan_model.dart';
import '../models/validate_code_request.dart';
import '../models/validate_code_response_model.dart';

abstract interface class SubscriptionsRemoteDataSource {
  /// `GET /api/subscriptions/plans` — returns a **raw JSON array**, no
  /// envelope. Public endpoint (works pre-auth) but the consumer adds
  /// `Authorization` if a token is present — harmless.
  Future<List<SubscriptionPlanModel>> getPlans();

  /// `GET /api/subscriptions/current` — returns either the subscription
  /// object or a literal `null` body for non-subscribers. Returns
  /// `null` for the not-subscribed case; throws on transport errors.
  Future<CurrentSubscriptionModel?> getCurrent();

  /// `POST /api/subscriptions/subscribe { pricingId, discountCode }`.
  /// Returns the resulting `CurrentSubscription`. The HTTP consumer's
  /// raw handler converts `{success: false, message}` payloads into
  /// `ServerException` so the repository sees them as failures.
  Future<CurrentSubscriptionModel> subscribe({
    required int pricingId,
    String? discountCode,
  });

  /// `POST /api/subscriptions/validate-code` — **raw** (no envelope). Returns
  /// the parsed [ValidateCodeResponseModel]; an invalid code is a normal 200
  /// with `valid:false`, not an error. Throws on transport / HTTP errors.
  Future<ValidateCodeResponseModel> validateCode(ValidateCodeRequest request);
}

class SubscriptionsRemoteDataSourceImpl
    implements SubscriptionsRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const SubscriptionsRemoteDataSourceImpl({required ApiConsumer apiConsumer})
      : _apiConsumer = apiConsumer;

  @override
  Future<List<SubscriptionPlanModel>> getPlans() async {
    AppLogger.debug('FETCH SUBSCRIPTION PLANS', tag: 'SUBSCRIPTIONS');
    final body = await _apiConsumer.getRaw(EndPoints.subscriptionPlans);
    if (body is! List) {
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    final plans = body
        .whereType<Map<String, dynamic>>()
        .map(SubscriptionPlanModel.fromJson)
        .toList();
    AppLogger.info(
      'Subscription plans — ${plans.length} plan(s)',
      tag: 'SUBSCRIPTIONS',
    );
    return plans;
  }

  @override
  Future<CurrentSubscriptionModel?> getCurrent() async {
    AppLogger.debug('FETCH CURRENT SUBSCRIPTION', tag: 'SUBSCRIPTIONS');
    final body = await _apiConsumer.getRaw(EndPoints.currentSubscription);
    if (body == null) {
      AppLogger.info('No active subscription', tag: 'SUBSCRIPTIONS');
      return null;
    }
    if (body is! Map<String, dynamic>) {
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    final model = CurrentSubscriptionModel.fromJson(body);
    AppLogger.info(
      'Current subscription — plan ${model.plan.id} '
      'expires ${model.expiresAt.toIso8601String()}',
      tag: 'SUBSCRIPTIONS',
    );
    return model;
  }

  @override
  Future<CurrentSubscriptionModel> subscribe({
    required int pricingId,
    String? discountCode,
  }) async {
    AppLogger.debug(
      'SUBSCRIBE pricingId=$pricingId code=${discountCode ?? "(none)"}',
      tag: 'SUBSCRIPTIONS',
    );
    final body = await _apiConsumer.postRaw(
      EndPoints.subscribe,
      body: {
        'pricingId': pricingId,
        if (discountCode != null && discountCode.isNotEmpty)
          'discountCode': discountCode,
      },
    );
    if (body is! Map<String, dynamic>) {
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw ServerException(
        message: body['message'] as String? ?? LocaleKeys.errors_generic,
      );
    }
    AppLogger.info('Subscribe success', tag: 'SUBSCRIPTIONS');
    return CurrentSubscriptionModel.fromJson(data);
  }

  @override
  Future<ValidateCodeResponseModel> validateCode(
    ValidateCodeRequest request,
  ) async {
    AppLogger.debug(
      'VALIDATE CODE product=${request.productId} platform=${request.platform}',
      tag: 'SUBSCRIPTIONS',
    );
    final body = await _apiConsumer.postRaw(
      EndPoints.validateCode,
      body: request.toJson(),
    );
    if (body is! Map<String, dynamic>) {
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    final model = ValidateCodeResponseModel.fromJson(body);
    AppLogger.info(
      'Validate code — valid=${model.valid} discount=${model.discountPercent}%',
      tag: 'SUBSCRIPTIONS',
    );
    return model;
  }
}
