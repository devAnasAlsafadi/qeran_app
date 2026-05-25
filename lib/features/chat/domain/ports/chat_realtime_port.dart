import '../entities/chat_message.dart';
import '../entities/messages_read_event.dart';
import '../entities/realtime_status.dart';

/// Domain-side contract for the realtime layer. Concrete impl lives
/// in `data/datasources/` and uses SignalR; the cubit only sees this
/// interface so tests can swap a fake.
///
/// Receive-only by design: outbound (`SendMessage`, `ShareProfile`,
/// `MarkAsRead` hub methods) is NOT exposed because we route every
/// outbound action through REST. REST gives us an idempotent ack
/// with the server-assigned id, which is the linchpin of dedup.
abstract class ChatRealtimePort {
  /// Latest known status (synchronous read for builders).
  RealtimeStatus get status;

  /// Status transitions: disconnected → connecting → connected ↔
  /// reconnecting → disconnected (closed).
  Stream<RealtimeStatus> get statusStream;

  /// `ReceiveMessage` event. The cubit dedups by `serverId`.
  Stream<ChatMessage> get incomingMessages;

  /// `MessagesRead` event. The cubit flips `isRead` on outgoing only.
  Stream<MessagesReadEvent> get messagesRead;

  /// Idempotent. Disconnects an existing session if one is open.
  /// `accessToken` is queried at every connect (and reconnect) so a
  /// rotated token is picked up automatically.
  Future<void> connect({
    required Future<String?> Function() accessTokenProvider,
  });

  Future<void> disconnect();
}
