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
  final SubscriptionFeaturesModel features;
  final List<SubscriptionPricingModel> pricings;

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
    required this.features,
    required this.pricings,
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
      features: SubscriptionFeaturesModel.fromJson(
        (json['features'] as Map<String, dynamic>?) ?? const {},
      ),
      pricings: (json['pricings'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SubscriptionPricingModel.fromJson)
          .toList(),
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
        features: features.toEntity(),
        pricings: pricings.map((p) => p.toEntity()).toList(),
      );
}
