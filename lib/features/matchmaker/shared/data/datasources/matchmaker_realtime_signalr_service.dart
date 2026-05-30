import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';

import '../../domain/entities/compatibility_case_update.dart';
import '../../domain/entities/matchmaker_realtime_status.dart';
import '../../domain/ports/matchmaker_realtime_port.dart';
import 'matchmaker_realtime_event_parser.dart';

/// Matchmaker-owned `MatchmakerRealtimePort` backed by `signalr_netcore`.
///
/// A SEPARATE instance from the user-side chat realtime service (Approach
/// B / full isolation): same hub URL + auth pattern, but its own
/// `HubConnection`, broadcast streams, and lifecycle. Nothing here can
/// affect chat behavior.
///
/// Receive-only. 4c-1 subscribes `CompatibilityCaseUpdated`;
/// `ReceiveMessage` (list liveness) is deferred to 4c-2. Auth:
/// `accessTokenFactory` is queried on every connect AND every reconnect
/// (`withAutomaticReconnect`) so a rotated JWT is picked up automatically.
class MatchmakerRealtimeSignalRService implements MatchmakerRealtimePort {
  final Future<String?> Function() _accessTokenProvider;

  /// Override in tests to avoid spinning up a real hub. The default
  /// builds the production `HubConnection`.
  final HubConnection Function(String url, AccessTokenFactory tokenFactory)
      _connectionFactory;

  HubConnection? _connection;
  MatchmakerRealtimeStatus _status = MatchmakerRealtimeStatus.disconnected;

  final StreamController<MatchmakerRealtimeStatus> _statusController =
      StreamController<MatchmakerRealtimeStatus>.broadcast();
  final StreamController<CompatibilityCaseUpdate> _caseUpdatesController =
      StreamController<CompatibilityCaseUpdate>.broadcast();

  MatchmakerRealtimeSignalRService({
    required Future<String?> Function() accessTokenProvider,
    HubConnection Function(String, AccessTokenFactory)? connectionFactory,
  })  : _accessTokenProvider = accessTokenProvider,
        _connectionFactory = connectionFactory ?? _defaultFactory;

  static HubConnection _defaultFactory(
    String url,
    AccessTokenFactory tokenFactory,
  ) {
    return HubConnectionBuilder()
        .withUrl(
          url,
          options: HttpConnectionOptions(accessTokenFactory: tokenFactory),
        )
        .withAutomaticReconnect()
        .build();
  }

  @override
  MatchmakerRealtimeStatus get status => _status;

  @override
  Stream<MatchmakerRealtimeStatus> get statusStream => _statusController.stream;

  @override
  Stream<CompatibilityCaseUpdate> get caseUpdates =>
      _caseUpdatesController.stream;

  @override
  Future<void> connect() async {
    // Idempotent: tear down any previous session first so we never leak
    // two parallel HubConnections.
    await disconnect();

    final connection = _connectionFactory(EndPoints.chatHubUrl, _tokenFactory);
    _connection = connection;

    connection.on('CompatibilityCaseUpdated', _onCaseUpdated);
    _wireLifecycleCallbacks(connection);
    await _start(connection);
  }

  /// `AccessTokenFactory` requires a non-null `Future<String>`; coerce a
  /// null/missing token to empty so the server simply 401s instead of
  /// throwing locally.
  Future<String> _tokenFactory() async {
    final raw = await _accessTokenProvider();
    return raw ?? '';
  }

  void _wireLifecycleCallbacks(HubConnection connection) {
    connection.onreconnecting(({Exception? error}) {
      AppLogger.warning('MM-RT — reconnecting (error=$error)', tag: 'MM-RT');
      _setStatus(MatchmakerRealtimeStatus.reconnecting);
    });
    connection.onreconnected(({String? connectionId}) {
      AppLogger.info('MM-RT — reconnected id=$connectionId', tag: 'MM-RT');
      _setStatus(MatchmakerRealtimeStatus.connected);
    });
    connection.onclose(({Exception? error}) {
      AppLogger.warning('MM-RT — closed (error=$error)', tag: 'MM-RT');
      _setStatus(MatchmakerRealtimeStatus.disconnected);
    });
  }

  Future<void> _start(HubConnection connection) async {
    _setStatus(MatchmakerRealtimeStatus.connecting);
    try {
      await connection.start();
      AppLogger.info('MM-RT — connected', tag: 'MM-RT');
      _setStatus(MatchmakerRealtimeStatus.connected);
    } catch (e, st) {
      AppLogger.error(
        'MM-RT — connect failed: $e',
        error: e,
        stack: st,
        tag: 'MM-RT',
      );
      _setStatus(MatchmakerRealtimeStatus.disconnected);
      _connection = null;
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    final conn = _connection;
    _connection = null;
    if (conn == null) return; // Already disconnected — stay idempotent.
    try {
      await conn.stop();
    } catch (e) {
      AppLogger.warning('MM-RT — stop failed: $e', tag: 'MM-RT');
    }
    _setStatus(MatchmakerRealtimeStatus.disconnected);
  }

  /// Lifetime is the app singleton; close the controllers on shutdown /
  /// hot-restart. Not part of the port contract — DI owns the lifecycle.
  Future<void> dispose() async {
    await disconnect();
    await _statusController.close();
    await _caseUpdatesController.close();
  }

  @visibleForTesting
  void onCaseUpdatedForTest(List<Object?>? args) => _onCaseUpdated(args);

  void _onCaseUpdated(List<Object?>? args) {
    final update = MatchmakerRealtimeEventParser.parseCaseUpdated(args);
    if (update == null) return;
    if (_caseUpdatesController.isClosed) return;
    _caseUpdatesController.add(update);
  }

  void _setStatus(MatchmakerRealtimeStatus s) {
    if (_status == s) return;
    _status = s;
    if (!_statusController.isClosed) _statusController.add(s);
  }
}
