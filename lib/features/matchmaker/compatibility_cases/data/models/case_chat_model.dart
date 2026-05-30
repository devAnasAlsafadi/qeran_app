import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/case_chat.dart';

/// Wire model for the `chat` sub-object — all conversation ids attached to
/// a case. Modeled in full for M4 (chat deep-links); unused by the 3a UI.
class CaseChatModel {
  final int? myUserConversationId;
  final int? otherUserConversationId;
  final String? otherMatchmakerId;
  final int? otherMatchmakerConversationId;

  const CaseChatModel({
    required this.myUserConversationId,
    required this.otherUserConversationId,
    required this.otherMatchmakerId,
    required this.otherMatchmakerConversationId,
  });

  factory CaseChatModel.fromJson(Map<String, dynamic> json) => CaseChatModel(
        myUserConversationId: parseNullableInt(json['myUserConversationId']),
        otherUserConversationId:
            parseNullableInt(json['otherUserConversationId']),
        otherMatchmakerId: parseNullableString(json['otherMatchmakerId']),
        otherMatchmakerConversationId:
            parseNullableInt(json['otherMatchmakerConversationId']),
      );

  CaseChat toEntity() => CaseChat(
        myUserConversationId: myUserConversationId,
        otherUserConversationId: otherUserConversationId,
        otherMatchmakerId: otherMatchmakerId,
        otherMatchmakerConversationId: otherMatchmakerConversationId,
      );
}
