import '../../domain/entities/subscription_plan.dart';
import 'subscription_features_model.dart';
import 'subscription_pricing_model.dart';

class SubscriptionPlanModel {
  final int id;
  final String nameAr;
  final String nameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String icon;
  final String color;
  final int sortOrder;
  final bool isActive;
  final bool isPopular;
  final bool isFree;

  /// Backend plan tier — 0=Free, 1=Basic, 2=VIP (Tariq's live contract).
  /// Nullable: absent on older/partial payloads. Identify plans by this.
  final int? tier;

  /// Dashboard-controlled display bullets (newline-separated), per locale.
  /// Nullable — the UI falls back to the numeric checklist when absent.
  final String? featuresAr;
  final String? featuresEn;
  final SubscriptionFeaturesModel features;
  final List<SubscriptionPricingModel> pricings;
  final String? subtitleAr;
  final String? subtitleEn;
  final String? badgeAr;
  final String? badgeEn;
  final bool hasBadgeFields;

  const SubscriptionPlanModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.icon,
    required this.color,
    required this.sortOrder,
    required this.isActive,
    required this.isPopular,
    required this.isFree,
    required this.tier,
    required this.featuresAr,
    required this.featuresEn,
    required this.features,
    required this.pricings,
    this.subtitleAr,
    this.subtitleEn,
    this.badgeAr,
    this.badgeEn,
    this.hasBadgeFields = false,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      descriptionAr: json['descriptionAr'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
      icon: json['icon'] as String? ?? '',
      color: json['color'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      isPopular: json['isPopular'] as bool? ?? false,
      isFree: json['isFree'] as bool? ?? false,
      tier: (json['tier'] as num?)?.toInt(),
      featuresAr: json['featuresAr'] as String?,
      featuresEn: json['featuresEn'] as String?,
      features: SubscriptionFeaturesModel.fromJson(
        (json['features'] as Map<String, dynamic>?) ?? const {},
      ),
      pricings: (json['pricings'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SubscriptionPricingModel.fromJson)
          .toList(),
      subtitleAr: json['subtitleAr'] as String?,
      subtitleEn: json['subtitleEn'] as String?,
      badgeAr: json['badgeAr'] as String?,
      badgeEn: json['badgeEn'] as String?,
      hasBadgeFields:
          json.containsKey('badgeAr') || json.containsKey('badgeEn'),
    );
  }

  SubscriptionPlan toEntity() => SubscriptionPlan(
        id: id,
        nameAr: nameAr,
        nameEn: nameEn,
        descriptionAr: descriptionAr,
        descriptionEn: descriptionEn,
        icon: icon,
        color: color,
        sortOrder: sortOrder,
        isActive: isActive,
        isPopular: isPopular,
        isFree: isFree,
        tier: tier,
        featuresAr: featuresAr,
        featuresEn: featuresEn,
        features: features.toEntity(),
        pricings: pricings.map((p) => p.toEntity()).toList(),
        subtitleAr: subtitleAr,
        subtitleEn: subtitleEn,
        badgeAr: badgeAr,
        badgeEn: badgeEn,
        hasBadgeFields: hasBadgeFields,
      );
}
