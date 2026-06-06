import 'package:qeran/core/api/end_points.dart';

import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/matchmaker_user_row.dart';

/// Wire model for a row in any of the three user lists, built against the
/// real Swagger payloads. The common fields ([userId], [fullName],
/// [profileImageUrl], [assignedAt]) are always present; the extras
/// ([hasProfileImage] on pending; [chatConversationId] on the approved
/// lists; [subscriptionPlanName] / [subscriptionExpiresAt] on
/// approved-subscribed) parse to `null` on the lists that omit them.
class MatchmakerUserRowModel {
  final String userId;
  final String fullName;
  final String? profileImageUrl;
  final DateTime? assignedAt;
  final bool? hasProfileImage;
  final int? chatConversationId;
  final String? subscriptionPlanName;
  final DateTime? subscriptionExpiresAt;

  const MatchmakerUserRowModel({
    required this.userId,
    required this.fullName,
    required this.profileImageUrl,
    required this.assignedAt,
    required this.hasProfileImage,
    required this.chatConversationId,
    required this.subscriptionPlanName,
    required this.subscriptionExpiresAt,
  });

  factory MatchmakerUserRowModel.fromJson(Map<String, dynamic> json) {
    // Subscription is a nested object — `{ planName, expiresAt }` — present
    // only on approved-subscribed rows; `null` on pending + approved-
    // unsubscribed. A null map yields null fields, so this is safe across
    // all three lists.
    final subscription = parseNullableMap(json['subscription']);
    return MatchmakerUserRowModel(
      userId: parseString(json['userId']),
      fullName: parseString(json['fullName']),
      profileImageUrl: parseNullableString(json['profileImageUrl']),
      assignedAt: parseNullableDateTime(json['assignedAt']),
      hasProfileImage: parseNullableBool(json['hasProfileImage']),
      chatConversationId: parseNullableInt(json['chatConversationId']),
      subscriptionPlanName: parseNullableString(subscription?['planName']),
      subscriptionExpiresAt:
          parseNullableDateTime(subscription?['expiresAt']),
    );
  }

  MatchmakerUserRow toEntity() {
    final raw = profileImageUrl;
    return MatchmakerUserRow(
      userId: userId,
      fullName: fullName,
      // Server sends a relative path; absolutize once here so the UI's
      // MatchmakerUserAvatar only ever sees a ready URL.
      profileImageUrl:
          (raw == null || raw.isEmpty) ? null : EndPoints.absoluteUrl(raw),
      assignedAt: assignedAt,
      hasProfileImage: hasProfileImage,
      chatConversationId: chatConversationId,
      subscriptionPlanName: subscriptionPlanName,
      subscriptionExpiresAt: subscriptionExpiresAt,
    );
  }
}
