import 'package:qeran/core/app_logger.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/messages_read_event.dart';
import '../models/chat_message_model.dart';
import '../models/messages_read_event_model.dart';

/// Pure payload parsing for the two SignalR events. Extracted from
/// `ChatRealtimeSignalRService` so it can be unit-tested without
/// spinning up a real hub connection: the SignalR transport hands us
/// `List<Object?>?` and these helpers turn that into validated
/// domain entities, or null on a malformed payload.
class ChatRealtimeEventParser {
  ChatRealtimeEventParser._();

  /// Returns a parsed `ChatMessage` for a valid `ReceiveMessage`
  /// payload, or `null` if the wire shape is unexpected. Never throws.
  static ChatMessage? parseReceiveMessage(List<Object?>? args) {
    final map = _firstMap(args);
    if (map == null) {
      AppLogger.warning(
        'CHAT — SignalR ReceiveMessage: missing or malformed args',
        tag: 'CHAT',
      );
      return null;
    }
    try {
      return ChatMessageModel.fromJson(map).toEntity();
    } catch (e) {
      AppLogger.error(
        'CHAT — SignalR ReceiveMessage parse failed: $e',
        error: e,
        tag: 'CHAT',
      );
      return null;
    }
  }

  /// Returns a parsed `MessagesReadEvent` for a valid `MessagesRead`
  /// payload, or `null` if the wire shape is unexpected. Never throws.
  static MessagesReadEvent? parseMessagesRead(List<Object?>? args) {
    final map = _firstMap(args);
    if (map == null) {
      AppLogger.warning(
        'CHAT — SignalR MessagesRead: missing or malformed args',
        tag: 'CHAT',
      );
      return null;
    }
    try {
      return MessagesReadEventModel.fromJson(map).toEntity();
    } catch (e) {
      AppLogger.error(
        'CHAT — SignalR MessagesRead parse failed: $e',
        error: e,
        tag: 'CHAT',
      );
      return null;
    }
  }

  /// Coerces `args[0]` into a `Map<String, dynamic>` if possible.
  /// SignalR may hand us a `Map<dynamic, dynamic>` depending on JSON
  /// implementation; we normalise to the typed map our models expect.
  static Map<String, dynamic>? _firstMap(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    final raw = args.first;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      try {
        return Map<String, dynamic>.from(raw);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
