import 'package:qeran/core/app_logger.dart';

import '../../domain/entities/badge_update_event.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/messages_read_event.dart';
import '../models/badge_update_event_model.dart';
import '../models/chat_message_model.dart';
import '../models/messages_read_event_model.dart';

/// Pure payload parsing for the SignalR events. Extracted from
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

  /// Returns a parsed `BadgeUpdateEvent` for a valid `BadgeUpdated`
  /// payload, or `null` if the wire shape is unexpected. Never throws.
  ///
  /// An unrecognised `tab` is NOT rejected. The contract is to ignore keys we
  /// do not know, and the cubit already stores them where no getter reads
  /// them — validating here would mean editing this file every time the
  /// backend grows a tab.
  static BadgeUpdateEvent? parseBadgeUpdate(List<Object?>? args) {
    final map = _firstMap(args);
    if (map == null) {
      AppLogger.warning(
        'CHAT — SignalR BadgeUpdated: missing or malformed args',
        tag: 'CHAT',
      );
      return null;
    }
    try {
      final event = BadgeUpdateEventModel.fromJson(map).toEntity();
      // A tabless event names nothing to update — drop it here rather than
      // publish something every consumer would have to skip.
      if (event.tab.isEmpty) {
        AppLogger.warning(
          'CHAT — SignalR BadgeUpdated: empty tab, dropped',
          tag: 'CHAT',
        );
        return null;
      }
      return event;
    } catch (e) {
      AppLogger.error(
        'CHAT — SignalR BadgeUpdated parse failed: $e',
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
