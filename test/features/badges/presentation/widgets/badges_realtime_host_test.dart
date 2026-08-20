import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/badges/domain/entities/badge_counts.dart';
import 'package:qeran/features/badges/domain/entities/badge_tab_keys.dart';
import 'package:qeran/features/badges/domain/usecases/get_badges_usecase.dart';
import 'package:qeran/features/badges/domain/usecases/mark_tab_seen_usecase.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import 'package:qeran/features/badges/presentation/widgets/badges_realtime_host.dart';
import 'package:qeran/features/chat/domain/entities/badge_update_event.dart';
import 'package:qeran/features/chat/domain/entities/chat_message.dart';
import 'package:qeran/features/chat/domain/entities/messages_read_event.dart';
import 'package:qeran/features/chat/domain/entities/realtime_status.dart';
import 'package:qeran/features/chat/domain/ports/chat_realtime_port.dart';

/// Drives the two hub streams by hand — no `signalr_netcore`, no server.
class _FakePort implements ChatRealtimePort {
  RealtimeStatus _status = RealtimeStatus.disconnected;
  final _statusController = StreamController<RealtimeStatus>.broadcast();
  final _badgeController = StreamController<BadgeUpdateEvent>.broadcast();

  @override
  RealtimeStatus get status => _status;
  @override
  Stream<RealtimeStatus> get statusStream => _statusController.stream;
  @override
  Stream<BadgeUpdateEvent> get badgeUpdates => _badgeController.stream;
  @override
  Stream<ChatMessage> get incomingMessages => const Stream.empty();
  @override
  Stream<MessagesReadEvent> get messagesRead => const Stream.empty();

  @override
  Future<void> connect({
    required ChatAccessTokenProvider accessTokenProvider,
  }) async => setStatus(RealtimeStatus.connected);

  @override
  Future<void> disconnect() async => setStatus(RealtimeStatus.disconnected);

  void setStatus(RealtimeStatus s) {
    if (_status == s) return;
    _status = s;
    _statusController.add(s);
  }

  void emitBadge(String tab, int count) =>
      _badgeController.add(BadgeUpdateEvent(tab: tab, count: count));

  Future<void> close() async {
    await _statusController.close();
    await _badgeController.close();
  }
}

class _FakeMarkTabSeen extends Fake implements MarkTabSeenUseCase {}

/// Counts refetches instead of performing them — `refresh` is the whole
/// question for the reconnect rule.
class _SpyBadgesCubit extends BadgesCubit {
  _SpyBadgesCubit()
    : super(getBadges: _FakeGetBadges(), markTabSeen: _FakeMarkTabSeen());

  int refreshCalls = 0;

  @override
  Future<void> refresh() async => refreshCalls++;
}

class _FakeGetBadges extends Fake implements GetBadgesUseCase {}

Future<void> _pump(
  WidgetTester tester,
  _FakePort port,
  BadgesCubit badges, {
  bool mounted = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: mounted
          ? BadgesRealtimeHost(
              port: port,
              badges: badges,
              child: const SizedBox.shrink(),
            )
          : const SizedBox.shrink(),
    ),
  );
  await tester.pump();
}

void main() {
  late _FakePort port;
  late _SpyBadgesCubit badges;

  setUp(() {
    port = _FakePort();
    badges = _SpyBadgesCubit();
  });

  tearDown(() async {
    await port.close();
    await badges.close();
  });

  testWidgets('a hub event assigns the count it carries', (tester) async {
    await _pump(tester, port, badges);

    port.emitBadge(BadgeTabKeys.likes, 3);
    await tester.pump();

    expect(badges.state.likes, 3);
  });

  // The absolute-count rule, which is the whole reason `applyUpdate` assigns.
  // Adding would double whatever a REST refresh had already counted.
  testWidgets('a second event replaces the first, never adds to it', (
    tester,
  ) async {
    await _pump(tester, port, badges);

    port.emitBadge(BadgeTabKeys.likes, 3);
    await tester.pump();
    port.emitBadge(BadgeTabKeys.likes, 5);
    await tester.pump();

    expect(badges.state.likes, 5);
  });

  // The shell already fetched on mount. Refetching again the moment the socket
  // comes up would be two requests for one answer.
  testWidgets('the FIRST connect does not refetch', (tester) async {
    await _pump(tester, port, badges);

    port.setStatus(RealtimeStatus.connected);
    await tester.pump();

    expect(badges.refreshCalls, 0);
  });

  // A socket that dropped and came back missed every event in between, and
  // nothing replays them.
  testWidgets('a reconnect refetches', (tester) async {
    await _pump(tester, port, badges);

    port.setStatus(RealtimeStatus.connected);
    port.setStatus(RealtimeStatus.reconnecting);
    port.setStatus(RealtimeStatus.connected);
    await tester.pump();

    expect(badges.refreshCalls, 1);
  });

  // The shell connects before this widget mounts, and a broadcast stream does
  // not replay: without seeding from the port's current status, the spent
  // `connected` would leave the reconnect rule disarmed for the whole session.
  testWidgets('mounting onto an already-connected port arms the rule', (
    tester,
  ) async {
    port.setStatus(RealtimeStatus.connected);
    await _pump(tester, port, badges);

    port.setStatus(RealtimeStatus.disconnected);
    port.setStatus(RealtimeStatus.connected);
    await tester.pump();

    expect(badges.refreshCalls, 1);
  });

  testWidgets('unmounting stops listening', (tester) async {
    await _pump(tester, port, badges);
    await _pump(tester, port, badges, mounted: false);

    port.emitBadge(BadgeTabKeys.likes, 4);
    port.setStatus(RealtimeStatus.connected);
    port.setStatus(RealtimeStatus.reconnecting);
    port.setStatus(RealtimeStatus.connected);
    await tester.pump();

    expect(badges.state, const BadgeCounts.empty());
    expect(badges.refreshCalls, 0);
  });
}
