import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/utils/server_datetime.dart';

import '../../domain/entities/current_subscription.dart';
import 'subscription_plan_model.dart';
import 'subscription_pricing_model.dart';

class CurrentSubscriptionModel {
  final int id;
  final SubscriptionPlanModel plan;
  final SubscriptionPricingModel pricing;
  final DateTime startsAt;
  final DateTime expiresAt;

  /// False when `expiresAt` was missing/unparseable and fell back to `now`.
  /// The UI must NOT read that fallback as "expired" — it's an unknown state.
  final bool hasReliableExpiry;

  final bool isActive;
  final int likesUsed;
  final int likesRemaining;
  final int seriousInterestsUsed;
  final int seriousInterestsRemaining;
  final int photoExchangesUsed;
  final int photoExchangesRemaining;

  const CurrentSubscriptionModel({
    required this.id,
    required this.plan,
    required this.pricing,
    required this.startsAt,
    required this.expiresAt,
    required this.hasReliableExpiry,
    required this.isActive,
    required this.likesUsed,
    required this.likesRemaining,
    required this.seriousInterestsUsed,
    required this.seriousInterestsRemaining,
    required this.photoExchangesUsed,
    required this.photoExchangesRemaining,
  });

  factory CurrentSubscriptionModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    // Backend timestamps are UTC without a 'Z' marker — parseServerDateTime
    // interprets them as UTC (see server_datetime.dart). A missing/unparseable
    // expiry must NOT be silently treated as "now" (which reads as expired):
    // flag it so the UI can show an "unknown" state instead.
    final parsedExpires = parseServerDateTime(json['expiresAt']);
    final hasReliableExpiry = parsedExpires != null;
    if (!hasReliableExpiry) {
      AppLogger.error(
        'CurrentSubscription: expiresAt missing/unparseable '
        '(raw=${json['expiresAt']}) — treating as unknown, not expired',
        tag: 'SUBSCRIPTIONS',
      );
    }
    return CurrentSubscriptionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      plan: SubscriptionPlanModel.fromJson(
        (json['plan'] as Map<String, dynamic>?) ?? const {},
      ),
      pricing: SubscriptionPricingModel.fromJson(
        (json['pricing'] as Map<String, dynamic>?) ?? const {},
      ),
      startsAt: parseServerDateTime(json['startsAt']) ?? now,
      expiresAt: parsedExpires ?? now,
      hasReliableExpiry: hasReliableExpiry,
      isActive: json['isActive'] as bool? ?? false,
      likesUsed: (json['likesUsed'] as num?)?.toInt() ?? 0,
      likesRemaining: (json['likesRemaining'] as num?)?.toInt() ?? 0,
      seriousInterestsUsed:
          (json['seriousInterestsUsed'] as num?)?.toInt() ?? 0,
      seriousInterestsRemaining:
          (json['seriousInterestsRemaining'] as num?)?.toInt() ?? 0,
      photoExchangesUsed:
          (json['photoExchangesUsed'] as num?)?.toInt() ?? 0,
      photoExchangesRemaining:
          (json['photoExchangesRemaining'] as num?)?.toInt() ?? 0,
    );
  }

  CurrentSubscription toEntity() => CurrentSubscription(
        id: id,
        plan: plan.toEntity(),
        pricing: pricing.toEntity(),
        startsAt: startsAt,
        expiresAt: expiresAt,
        hasReliableExpiry: hasReliableExpiry,
        isActive: isActive,
        likesUsed: likesUsed,
        likesRemaining: likesRemaining,
        seriousInterestsUsed: seriousInterestsUsed,
        seriousInterestsRemaining: seriousInterestsRemaining,
        photoExchangesUsed: photoExchangesUsed,
        photoExchangesRemaining: photoExchangesRemaining,
      );
}
