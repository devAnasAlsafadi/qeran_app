import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/data/display_name.dart';

import '../../../conversations/domain/entities/matchmaker_conversation.dart';
import '../../../shared/data/json_parsers.dart';

/// Wire model for one row of `GET /api/matchmaker/conversations/colleagues`.
///
/// The doc says this is the "same structure as user conversations"; the live
/// server uses the flat shape the shipped user-conversation model reads. To
/// stay safe against either, this parses DEFENSIVELY — `matchmakerId ?? userId`
/// and `name ?? fullName` — and produces the generic [MatchmakerConversation]
/// entity (reused unchanged for colleague↔colleague threads). The shipped
/// user-conversation model is left untouched (code wins).
class MatchmakerColleagueConversationModel {
  final String otherUserId;
  final String name;
  final String? profileImageUrl;
  final int conversationId;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final int unreadCount;

  const MatchmakerColleagueConversationModel({
    required this.otherUserId,
    required this.name,
    required this.profileImageUrl,
    required this.conversationId,
    required this.lastMessageAt,
    required this.lastMessagePreview,
    required this.unreadCount,
  });

  factory MatchmakerColleagueConversationModel.fromJson(
    Map<String, dynamic> json,
  ) =>
      MatchmakerColleagueConversationModel(
        otherUserId: parseString(json['matchmakerId'] ?? json['userId']),
        name: parseDisplayName(json),
        profileImageUrl: parseNullableString(json['profileImageUrl']),
        conversationId: parseInt(json['conversationId']),
        lastMessageAt: parseNullableDateTime(json['lastMessageAt']),
        lastMessagePreview: parseNullableString(json['lastMessagePreview']),
        unreadCount: parseInt(json['unreadCount']),
      );

  MatchmakerConversation toEntity() {
    final raw = profileImageUrl;
    return MatchmakerConversation(
      userId: otherUserId,
      fullName: name,
      profileImageUrl:
          (raw == null || raw.isEmpty) ? null : EndPoints.absoluteUrl(raw),
      conversationId: conversationId,
      lastMessageAt: lastMessageAt,
      lastMessagePreview: lastMessagePreview,
      unreadCount: unreadCount,
    );
  }
}
