import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/data/display_name.dart';
import 'package:qeran/core/enum/gender.dart';

import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/case_user.dart';

/// Wire model for `myUser` / `otherUser` on a compatibility case, built
/// against the real Swagger payload. `age` and `gender` are newly-added
/// nullable fields (absent from the current payload → parse to `null`).
/// The relative `profileImageUrl` is absolutized here so the UI's
/// MatchmakerUserAvatar only ever sees a ready URL.
class CaseUserModel {
  final String userId;
  final String name;
  final String? profileImageUrl;
  final int? age;
  final String? gender;
  final bool isAssignedToMe;

  const CaseUserModel({
    required this.userId,
    required this.name,
    required this.profileImageUrl,
    required this.age,
    required this.gender,
    required this.isAssignedToMe,
  });

  factory CaseUserModel.fromJson(Map<String, dynamic> json) => CaseUserModel(
        userId: parseString(json['userId']),
        name: parseDisplayName(json),
        profileImageUrl: parseNullableString(json['profileImageUrl']),
        age: parseNullableInt(json['age']),
        gender: parseNullableString(json['gender']),
        isAssignedToMe: parseBool(json['isAssignedToMe']),
      );

  CaseUser toEntity() {
    final raw = profileImageUrl;
    return CaseUser(
      userId: userId,
      name: name,
      profileImageUrl:
          (raw == null || raw.isEmpty) ? null : EndPoints.absoluteUrl(raw),
      age: age,
      gender: Gender.fromString(gender),
      isAssignedToMe: isAssignedToMe,
    );
  }
}
