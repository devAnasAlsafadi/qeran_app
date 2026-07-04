import '../../domain/entities/subscription_pricing.dart';

class SubscriptionPricingModel {
  final int id;
  final int planId;
  final int durationDays;
  final String? labelAr;
  final String? labelEn;
  final double price;
  final double? originalPrice;
  final int discountPercent;
  final double monthlyEquivalent;
  final int sortOrder;
  final bool isActive;
  final bool isPopular;

  /// Canonical cross-store product id for this pricing period (backend
  /// `storeProductId`) — the primary key for RevenueCat lookup. `null` for a
  /// period not linked to the store (e.g. the free plan).
  final String? storeProductId;

  /// Platform-specific fallbacks used when [storeProductId] is absent (the
  /// stores may diverge). Source: backend `appleProductId` / `googleProductId`.
  final String? appleProductId;
  final String? googleProductId;

  const SubscriptionPricingModel({
    required this.id,
    required this.planId,
    required this.durationDays,
    required this.labelAr,
    required this.labelEn,
    required this.price,
    required this.originalPrice,
    required this.discountPercent,
    required this.monthlyEquivalent,
    required this.sortOrder,
    required this.isActive,
    required this.isPopular,
    required this.storeProductId,
    required this.appleProductId,
    required this.googleProductId,
  });

  factory SubscriptionPricingModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPricingModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      planId: (json['planId'] as num?)?.toInt() ?? 0,
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
      labelAr: json['labelAr'] as String?,
      labelEn: json['labelEn'] as String?,
      price: ((json['price'] as num?) ?? 0).toDouble(),
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
      monthlyEquivalent:
          ((json['monthlyEquivalent'] as num?) ?? 0).toDouble(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      isPopular: json['isPopular'] as bool? ?? false,
      storeProductId: json['storeProductId'] as String?,
      appleProductId: json['appleProductId'] as String?,
      googleProductId: json['googleProductId'] as String?,
    );
  }

  SubscriptionPricing toEntity() => SubscriptionPricing(
        id: id,
        planId: planId,
        durationDays: durationDays,
        labelAr: labelAr,
        labelEn: labelEn,
        price: price,
        originalPrice: originalPrice,
        discountPercent: discountPercent,
        monthlyEquivalent: monthlyEquivalent,
        sortOrder: sortOrder,
        isActive: isActive,
        isPopular: isPopular,
        storeProductId: storeProductId,
        appleProductId: appleProductId,
        googleProductId: googleProductId,
      );
}
