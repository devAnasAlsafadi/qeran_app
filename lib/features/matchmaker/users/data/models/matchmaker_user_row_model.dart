import 'package:qeran/core/api/end_points.dart';

import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/matchmaker_user_row.dart';

/// Wire model for a row in any of the three user lists (backend doc
/// §5.1–5.3). The shared core fields are always present; the extras
/// (`chatConversationId`, `subscriptionPlanName`, `subscriptionExpiresAt`)
/// appear only on the lists that carry them and parse to `null` otherwise.
class MatchmakerUserRowModel {
  final String userId;
  final String name;
  final String gender;
  final int? age;
  final bool hasProfileImage;
  final String? profileImageUrl;
  final DateTime? questionsCompletedAt;
  final int? chatConversationId;
  final String? subscriptionPlanName;
  final DateTime? subscriptionExpiresAt;

  const MatchmakerUserRowModel({
    required this.userId,
    required this.name,
    required this.gender,
    required this.age,
    required this.hasProfileImage,
    required this.profileImageUrl,
    required this.questionsCompletedAt,
    required this.chatConversationId,
    required this.subscriptionPlanName,
    required this.subscriptionExpiresAt,
  });

  factory MatchmakerUserRowModel.fromJson(Map<String, dynamic> json) =>
      MatchmakerUserRowModel(
        userId: parseString(json['userId']),
        name: parseString(json['name']),
        gender: parseString(json['gender']),
        age: parseNullableInt(json['age']),
        hasProfileImage: parseBool(json['hasProfileImage']),
        profileImageUrl: parseNullableString(json['profileImageUrl']),
        questionsCompletedAt:
            parseNullableDateTime(json['questionsCompletedAt']),
        chatConversationId: parseNullableInt(json['chatConversationId']),
        subscriptionPlanName: parseNullableString(json['subscriptionPlanName']),
        subscriptionExpiresAt:
            parseNullableDateTime(json['subscriptionExpiresAt']),
      );

  MatchmakerUserRow toEntity() {
    final raw = profileImageUrl;
    return MatchmakerUserRow(
      userId: userId,
      name: name,
      gender: gender,
      age: age,
      hasProfileImage: hasProfileImage,
      // Server sends a relative path; absolutize once here so the UI's
      // MatchmakerUserAvatar only ever sees a ready URL.
      profileImageUrl:
          (raw == null || raw.isEmpty) ? null : EndPoints.absoluteUrl(raw),
      questionsCompletedAt: questionsCompletedAt,
      chatConversationId: chatConversationId,
      subscriptionPlanName: subscriptionPlanName,
      subscriptionExpiresAt: subscriptionExpiresAt,
    );
  }
}
