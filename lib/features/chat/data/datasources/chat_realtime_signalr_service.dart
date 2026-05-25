import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/messages_read_event.dart';
import '../../domain/entities/realtime_status.dart';
import '../../domain/ports/chat_realtime_port.dart';
import 'chat_realtime_event_parser.dart';

/// Concrete `ChatRealtimePort` backed by `signalr_netcore`.
///
/// **Receive-only by design.** Outbound (`SendMessage`, `ShareProfile`,
/// `MarkAsRead` hub methods) is intentionally not exposed — every
/// outbound action goes through REST so we get a synchronous ack with
/// a real server id, which is what the cubit's dedup pipeline keys
/// off of.
///
/// Two server-emitted events are subscribed: `ReceiveMessage` (full
/// `ChatMessageDto` — same shape as REST) and `MessagesRead`
/// (`{ conversationId, readByUserId, readAt }`). Both are parsed by
/// `ChatRealtimeEventParser` (testable in isolation); failures are
/// logged and dropped so a single malformed broadcast never tears
/// down the stream.
///
/// Auth: `accessTokenFactory` is queried on every connect AND every
/// reconnect (built-in `withAutomaticReconnect`) so a rotated JWT is
/// picked up automatically when refresh lands later.
class ChatRealtimeSignalRService implements ChatRealtimePort {
  /// Replace via constructor in tests to avoid spinning up the real
  /// hub. The default factory builds the production `HubConnection`.
  final HubConnection Function(String url, AccessTokenFactory tokenFactory)
      _connectionFactory;

  HubConnection? _connection;
  RealtimeStatus _status = RealtimeStatus.disconnected;

  final StreamController<RealtimeStatus> _statusController =
      StreamController<RealtimeStatus>.broadcast();
  final StreamController<ChatMessage> _incomingController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<MessagesReadEvent> _messagesReadController =
      StreamController<MessagesReadEvent>.broadcast();

  ChatRealtimeSignalRService({
    HubConnection Function(String, AccessTokenFactory)? connectionFactory,
  }) : _connectionFactory = connectionFactory ?? _defaultFactory;

  static HubConnection _defaultFactory(
    String url,
    AccessTokenFactory tokenFactory,
  ) {
    return HubConnectionBuilder()
        .withUrl(
          url,
          options: HttpConnectionOptions(
            accessTokenFactory: tokenFactory,
          ),
        )
        .withAutomaticReconnect()
        .build();
  }

  @override
  RealtimeStatus get status => _status;

  @override
  Stream<RealtimeStatus> get statusStream => _statusController.stream;

  @override
  Stream<ChatMessage> get incomingMessages => _incomingController.stream;

  @override
  Stream<MessagesReadEvent> get messagesRead =>
      _messagesReadController.stream;

  @override
  Future<void> connect({
    required Future<String?> Function() accessTokenProvider,
  }) async {
    // Idempotent: tear down any previous session first so we never
    // leak two parallel HubConnections.
    await disconnect();

    // `AccessTokenFactory` requires a non-null `Future<String>`; we
    // coerce null/missing token to empty so the server simply 401s
    // instead of throwing locally.
    Future<String> tokenFactory() async {
      final raw = await accessTokenProvider();
      return raw ?? '';
    }

    final connection = _connectionFactory(EndPoints.chatHubUrl, tokenFactory);
    _connection = connection;

    // Event subscriptions.
    connection.on('ReceiveMessage', _onReceiveMessage);
    connection.on('MessagesRead', _onMessagesRead);

    // Lifecycle callbacks.
    connection.onreconnecting(({Exception? error}) {
      AppLogger.warning(
        'CHAT — SignalR reconnecting (error=$error)',
        tag: 'CHAT',
      );
      _setStatus(RealtimeStatus.reconnecting);
    });
    connection.onreconnected(({String? connectionId}) {
      AppLogger.info(
        'CHAT — SignalR reconnected id=$connectionId',
        tag: 'CHAT',
      );
      _setStatus(RealtimeStatus.connected);
    });
    connection.onclose(({Exception? error}) {
      AppLogger.warning(
        'CHAT — SignalR closed (error=$error)',
        tag: 'CHAT',
      );
      _setStatus(RealtimeStatus.disconnected);
    });

    _setStatus(RealtimeStatus.connecting);
    try {
      await connection.start();
      AppLogger.info('CHAT — SignalR connected', tag: 'CHAT');
      _setStatus(RealtimeStatus.connected);
    } catch (e, st) {
      AppLogger.error(
        'CHAT — SignalR connect failed: $e',
        error: e,
        stack: st,
        tag: 'CHAT',
      );
      _setStatus(RealtimeStatus.disconnected);
      _connection = null;
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    final conn = _connection;
    _connection = null;
    if (conn == null) {
      // Already disconnected — keep idempotent. Don't re-emit status.
      return;
    }
    try {
      await conn.stop();
    } catch (e) {
      AppLogger.warning('CHAT — SignalR stop failed: $e', tag: 'CHAT');
    }
    _setStatus(RealtimeStatus.disconnected);
  }

  /// Lifetime is the app singleton; close the controllers on hot-
  /// restart / shutdown via this. Not part of the port contract — DI
  /// owns the lifecycle.
  Future<void> dispose() async {
    await disconnect();
    await _statusController.close();
    await _incomingController.close();
    await _messagesReadController.close();
  }

  // ── Event dispatch (extracted for testability) ────────────────────

  @visibleForTesting
  void onReceiveMessageForTest(List<Object?>? args) => _onReceiveMessage(args);

  @visibleForTesting
  void onMessagesReadForTest(List<Object?>? args) => _onMessagesRead(args);

  void _onReceiveMessage(List<Object?>? args) {
    final msg = ChatRealtimeEventParser.parseReceiveMessage(args);
    if (msg == null) return;
    if (_incomingController.isClosed) return;
    _incomingController.add(msg);
  }

  void _onMessagesRead(List<Object?>? args) {
    final event = ChatRealtimeEventParser.parseMessagesRead(args);
    if (event == null) return;
    if (_messagesReadController.isClosed) return;
    _messagesReadController.add(event);
  }

  void _setStatus(RealtimeStatus s) {
    if (_status == s) return;
    _status = s;
    if (!_statusController.isClosed) {
      _statusController.add(s);
    }
  }
}
