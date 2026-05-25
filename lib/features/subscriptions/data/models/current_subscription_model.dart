import '../../domain/entities/current_subscription.dart';
import 'subscription_plan_model.dart';
import 'subscription_pricing_model.dart';

class CurrentSubscriptionModel {
  final int id;
  final SubscriptionPlanModel plan;
  final SubscriptionPricingModel pricing;
  final DateTime startsAt;
  final DateTime expiresAt;
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
    return CurrentSubscriptionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      plan: SubscriptionPlanModel.fromJson(
        (json['plan'] as Map<String, dynamic>?) ?? const {},
      ),
      pricing: SubscriptionPricingModel.fromJson(
        (json['pricing'] as Map<String, dynamic>?) ?? const {},
      ),
      startsAt: _parseDate(json['startsAt']) ?? now,
      expiresAt: _parseDate(json['expiresAt']) ?? now,
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

  static DateTime? _parseDate(dynamic raw) {
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw)?.toLocal();
    }
    return null;
  }

  CurrentSubscription toEntity() => CurrentSubscription(
        id: id,
        plan: plan.toEntity(),
        pricing: pricing.toEntity(),
        startsAt: startsAt,
        expiresAt: expiresAt,
        isActive: isActive,
        likesUsed: likesUsed,
        likesRemaining: likesRemaining,
        seriousInterestsUsed: seriousInterestsUsed,
        seriousInterestsRemaining: seriousInterestsRemaining,
        photoExchangesUsed: photoExchangesUsed,
        photoExchangesRemaining: photoExchangesRemaining,
      );
}
