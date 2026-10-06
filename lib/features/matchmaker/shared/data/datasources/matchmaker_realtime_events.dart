import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../domain/entities/community_post_status_change.dart';
import '../../domain/entities/compatibility_case_update.dart';
import '../../domain/entities/received_chat_message.dart';
import 'matchmaker_realtime_event_parser.dart';

/// The hub events her realtime connection hands on, each on its own
/// broadcast stream: `CompatibilityCaseUpdated` (the cases list),
/// `ReceiveMessage` (the conversations lists) and
/// `CommunityPostStatusChanged` (her processing posts, Phase 3).
mixin MatchmakerRealtimeEvents {
  final StreamController<CompatibilityCaseUpdate> _caseUpdatesController =
      StreamController<CompatibilityCaseUpdate>.broadcast();
  final StreamController<ReceivedChatMessage> _incomingController =
      StreamController<ReceivedChatMessage>.broadcast();
  final StreamController<CommunityPostStatusChange> _postStatusController =
      StreamController<CommunityPostStatusChange>.broadcast();

  Stream<CompatibilityCaseUpdate> get caseUpdates =>
      _caseUpdatesController.stream;

  Stream<ReceivedChatMessage> get incomingMessages =>
      _incomingController.stream;

  Stream<CommunityPostStatusChange> get postStatusChanges =>
      _postStatusController.stream;

  /// Subscribes [connection] to every event above.
  @protected
  void listenToEvents(HubConnection connection) {
    connection.on('CompatibilityCaseUpdated', _onCaseUpdated);
    connection.on('ReceiveMessage', _onMessage);
    connection.on('CommunityPostStatusChanged', _onPostStatus);
  }

  /// The streams end with the app singleton.
  @protected
  Future<void> closeEventStreams() async {
    await _caseUpdatesController.close();
    await _incomingController.close();
    await _postStatusController.close();
  }

  @visibleForTesting
  void onCaseUpdatedForTest(List<Object?>? args) => _onCaseUpdated(args);

  @visibleForTesting
  void onMessageForTest(List<Object?>? args) => _onMessage(args);

  @visibleForTesting
  void onPostStatusForTest(List<Object?>? args) => _onPostStatus(args);

  void _onCaseUpdated(List<Object?>? args) {
    final update = MatchmakerRealtimeEventParser.parseCaseUpdated(args);
    if (update == null) return;
    if (_caseUpdatesController.isClosed) return;
    _caseUpdatesController.add(update);
  }

  void _onMessage(List<Object?>? args) {
    final message = MatchmakerRealtimeEventParser.parseReceivedMessage(args);
    if (message == null) return;
    if (_incomingController.isClosed) return;
    _incomingController.add(message);
  }

  void _onPostStatus(List<Object?>? args) {
    final change = MatchmakerRealtimeEventParser.parsePostStatusChanged(args);
    if (change == null || _postStatusController.isClosed) return;
    _postStatusController.add(change);
  }
}
