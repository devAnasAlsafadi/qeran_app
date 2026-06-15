import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/subscription_plan.dart';

/// Wire model for a `subscription-plans` entry:
/// `{ planId, nameAr, nameEn, icon, color, subscriberCount }`.
///
/// `icon` + `color` are deliberately NOT parsed — the UI paints plans in our
/// own wine/gold identity (see [SubscriptionPlan]). Defensive parsers tolerate
/// int↔string drift so one odd field never collapses the rail.
class SubscriptionPlanModel {
  final int planId;
  final String nameAr;
  final String nameEn;
  final int subscriberCount;

  const SubscriptionPlanModel({
    required this.planId,
    required this.nameAr,
    required this.nameEn,
    required this.subscriberCount,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      planId: parseInt(json['planId']),
      nameAr: parseString(json['nameAr']),
      nameEn: parseString(json['nameEn']),
      subscriberCount: parseInt(json['subscriberCount']),
    );
  }

  SubscriptionPlan toEntity() => SubscriptionPlan(
        planId: planId,
        nameAr: nameAr,
        nameEn: nameEn,
        subscriberCount: subscriberCount,
      );
}
