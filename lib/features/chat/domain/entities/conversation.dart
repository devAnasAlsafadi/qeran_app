import 'package:equatable/equatable.dart';

import 'conversation_type.dart';

/// Future-proofing entity for `GET /api/chat/conversations`. The MVP
/// UI does not render a list (user has a single matchmaker
/// conversation), but the data layer parses this shape so the day a
/// list lands the work is data-only.
class Conversation extends Equatable {
  final int id;
  final String otherParticipantId;
  final String otherParticipantName;
  final String? otherParticipantImageUrl;
  final bool otherParticipantImageBlurred;
  final ConversationType type;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.otherParticipantId,
    required this.otherParticipantName,
    required this.otherParticipantImageUrl,
    required this.otherParticipantImageBlurred,
    required this.type,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [
        id,
        otherParticipantId,
        otherParticipantName,
        otherParticipantImageUrl,
        otherParticipantImageBlurred,
        type,
        lastMessage,
        lastMessageAt,
        unreadCount,
      ];
}
