import '../../domain/entities/subscription_features.dart';

class SubscriptionFeaturesModel {
  final int likesAllowed;
  final int seriousInterestsAllowed;
  final int photoExchangesAllowed;
  final int dailyProfileViewsAllowed;

  const SubscriptionFeaturesModel({
    required this.likesAllowed,
    required this.seriousInterestsAllowed,
    required this.photoExchangesAllowed,
    required this.dailyProfileViewsAllowed,
  });

  factory SubscriptionFeaturesModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionFeaturesModel(
      likesAllowed:
          (json['likesAllowed'] as num?)?.toInt() ?? 0,
      seriousInterestsAllowed:
          (json['seriousInterestsAllowed'] as num?)?.toInt() ?? 0,
      photoExchangesAllowed:
          (json['photoExchangesAllowed'] as num?)?.toInt() ?? 0,
      dailyProfileViewsAllowed:
          (json['dailyProfileViewsAllowed'] as num?)?.toInt() ?? 0,
    );
  }

  SubscriptionFeatures toEntity() => SubscriptionFeatures(
        likesAllowed: likesAllowed,
        seriousInterestsAllowed: seriousInterestsAllowed,
        photoExchangesAllowed: photoExchangesAllowed,
        dailyProfileViewsAllowed: dailyProfileViewsAllowed,
      );
}
