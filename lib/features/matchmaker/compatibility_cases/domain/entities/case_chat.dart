import 'package:equatable/equatable.dart';

/// Conversation ids attached to a case. Modeled in full for M4 (chat
/// deep-links from a case); not surfaced in the 3a list UI.
class CaseChat extends Equatable {
  final int? myUserConversationId;
  final int? otherUserConversationId;
  final String? otherMatchmakerId;
  final int? otherMatchmakerConversationId;

  const CaseChat({
    required this.myUserConversationId,
    required this.otherUserConversationId,
    required this.otherMatchmakerId,
    required this.otherMatchmakerConversationId,
  });

  @override
  List<Object?> get props => [
        myUserConversationId,
        otherUserConversationId,
        otherMatchmakerId,
        otherMatchmakerConversationId,
      ];
}
