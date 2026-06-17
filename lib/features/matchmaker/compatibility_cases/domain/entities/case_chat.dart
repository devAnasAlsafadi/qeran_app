import 'package:equatable/equatable.dart';

/// Conversation ids attached to a case. Modeled in full for M4 (chat
/// deep-links from a case); not surfaced in the 3a list UI.
class CaseChat extends Equatable {
  final int? myUserConversationId;
  final int? otherUserConversationId;
  final String? otherMatchmakerId;
  final int? otherMatchmakerConversationId;

  /// The other side's matchmaker name for the chat header — null in the same
  /// cases as [otherMatchmakerId] (both parties mine / other party unassigned).
  final String? otherMatchmakerName;

  /// RAW relative image path for that matchmaker (same format as user images,
  /// needs `EndPoints.absoluteUrl`). Null when [otherMatchmakerId] is null, or
  /// additionally when that matchmaker has no profile photo.
  final String? otherMatchmakerImageUrl;

  const CaseChat({
    required this.myUserConversationId,
    required this.otherUserConversationId,
    required this.otherMatchmakerId,
    required this.otherMatchmakerConversationId,
    required this.otherMatchmakerName,
    required this.otherMatchmakerImageUrl,
  });

  @override
  List<Object?> get props => [
        myUserConversationId,
        otherUserConversationId,
        otherMatchmakerId,
        otherMatchmakerConversationId,
        otherMatchmakerName,
        otherMatchmakerImageUrl,
      ];
}
