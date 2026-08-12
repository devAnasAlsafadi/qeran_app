import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/data/display_name.dart';

import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/matchmaker_conversation.dart';

/// Wire model for one row of `GET /api/matchmaker/conversations/users`, built
/// against the real Swagger payload — flat `fullName` (not `userName`) and a
/// flat `profileImageUrl` (not a nested object). The relative image path is
/// absolutized in [toEntity] so the UI's avatar only ever sees a ready URL.
class MatchmakerConversationModel {
  final String userId;
  final String fullName;
  final String? profileImageUrl;
  final int conversationId;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final int unreadCount;

  const MatchmakerConversationModel({
    required this.userId,
    required this.fullName,
    required this.profileImageUrl,
    required this.conversationId,
    required this.lastMessageAt,
    required this.lastMessagePreview,
    required this.unreadCount,
  });

  factory MatchmakerConversationModel.fromJson(Map<String, dynamic> json) =>
      MatchmakerConversationModel(
        userId: parseString(json['userId']),
        fullName: parseDisplayName(json),
        profileImageUrl: parseNullableString(json['profileImageUrl']),
        conversationId: parseInt(json['conversationId']),
        lastMessageAt: parseNullableDateTime(json['lastMessageAt']),
        lastMessagePreview: parseNullableString(json['lastMessagePreview']),
        unreadCount: parseInt(json['unreadCount']),
      );

  MatchmakerConversation toEntity() {
    final raw = profileImageUrl;
    return MatchmakerConversation(
      userId: userId,
      fullName: fullName,
      profileImageUrl:
          (raw == null || raw.isEmpty) ? null : EndPoints.absoluteUrl(raw),
      conversationId: conversationId,
      lastMessageAt: lastMessageAt,
      lastMessagePreview: lastMessagePreview,
      unreadCount: unreadCount,
    );
  }
}
