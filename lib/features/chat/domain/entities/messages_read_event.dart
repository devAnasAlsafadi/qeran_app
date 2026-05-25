import 'package:equatable/equatable.dart';

/// SignalR `MessagesRead` payload. Fires when the OTHER party in a
/// conversation taps `MarkAsRead` (REST or hub) — never for self.
/// The cubit walks local messages and flips `isRead: true` on every
/// message where `senderId == me && senderId != readByUserId`.
class MessagesReadEvent extends Equatable {
  final int conversationId;
  final String readByUserId;
  final DateTime readAt;

  const MessagesReadEvent({
    required this.conversationId,
    required this.readByUserId,
    required this.readAt,
  });

  @override
  List<Object?> get props => [conversationId, readByUserId, readAt];
}
