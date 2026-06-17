import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/case_chat.dart';

/// Wire model for the `chat` sub-object — all conversation ids attached to
/// a case. Modeled in full for M4 (chat deep-links); unused by the 3a UI.
class CaseChatModel {
  final int? myUserConversationId;
  final int? otherUserConversationId;
  final String? otherMatchmakerId;
  final int? otherMatchmakerConversationId;
  final String? otherMatchmakerName;

  /// RAW relative image path (same format as user images) — absolutized at the
  /// call site via `EndPoints.absoluteUrl`, kept raw here.
  final String? otherMatchmakerImageUrl;

  const CaseChatModel({
    required this.myUserConversationId,
    required this.otherUserConversationId,
    required this.otherMatchmakerId,
    required this.otherMatchmakerConversationId,
    required this.otherMatchmakerName,
    required this.otherMatchmakerImageUrl,
  });

  factory CaseChatModel.fromJson(Map<String, dynamic> json) => CaseChatModel(
        myUserConversationId: parseNullableInt(json['myUserConversationId']),
        otherUserConversationId:
            parseNullableInt(json['otherUserConversationId']),
        otherMatchmakerId: parseNullableString(json['otherMatchmakerId']),
        otherMatchmakerConversationId:
            parseNullableInt(json['otherMatchmakerConversationId']),
        otherMatchmakerName: parseNullableString(json['otherMatchmakerName']),
        otherMatchmakerImageUrl:
            parseNullableString(json['otherMatchmakerImageUrl']),
      );

  CaseChat toEntity() => CaseChat(
        myUserConversationId: myUserConversationId,
        otherUserConversationId: otherUserConversationId,
        otherMatchmakerId: otherMatchmakerId,
        otherMatchmakerConversationId: otherMatchmakerConversationId,
        otherMatchmakerName: otherMatchmakerName,
        otherMatchmakerImageUrl: otherMatchmakerImageUrl,
      );
}
