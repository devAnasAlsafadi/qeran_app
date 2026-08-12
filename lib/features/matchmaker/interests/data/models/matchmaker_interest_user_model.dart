import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/data/display_name.dart';

import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/matchmaker_interest_user.dart';

/// Wire model for the page `user` header.
/// ⚠️ Field names to confirm: userId / fullName / profileImageUrl / age.
class MatchmakerInterestUserModel {
  final String userId;
  final String fullName;
  final String? profileImageUrl;
  final int? age;

  const MatchmakerInterestUserModel({
    required this.userId,
    required this.fullName,
    required this.profileImageUrl,
    this.age,
  });

  factory MatchmakerInterestUserModel.fromJson(Map<String, dynamic> json) =>
      MatchmakerInterestUserModel(
        userId: parseString(json['userId']),
        fullName: parseDisplayName(json),
        profileImageUrl: parseNullableString(json['profileImageUrl']),
        age: parseNullableInt(json['age']),
      );

  MatchmakerInterestUser toEntity() {
    final raw = profileImageUrl;
    return MatchmakerInterestUser(
      userId: userId,
      fullName: fullName,
      profileImageUrl:
          (raw == null || raw.isEmpty) ? null : EndPoints.absoluteUrl(raw),
      age: age,
    );
  }
}
