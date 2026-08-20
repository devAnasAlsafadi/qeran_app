import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/chat/domain/entities/badge_update_event.dart';
import 'package:qeran/features/chat/domain/entities/chat_message.dart';
import 'package:qeran/features/chat/domain/entities/messages_read_event.dart';
import 'package:qeran/features/chat/domain/entities/realtime_status.dart';
import 'package:qeran/features/chat/domain/ports/chat_realtime_port.dart';
import 'package:qeran/features/chat/presentation/widgets/chat_realtime_host.dart';

/// Records the session calls without spinning up `signalr_netcore`. Mirrors
/// the real service's contract: `connect` tears down any live session first,
/// which is exactly why a second caller is not free.
class _FakePort implements ChatRealtimePort {
  RealtimeStatus _status = RealtimeStatus.disconnected;
  final _statusController = StreamController<RealtimeStatus>.broadcast();
  int connectCalls = 0;
  int disconnectCalls = 0;

  /// Makes `connect()` fail once, standing in for a dead network at launch.
  bool failNextConnect = false;

  @override
  RealtimeStatus get status => _status;
  @override
  Stream<RealtimeStatus> get statusStream => _statusController.stream;
  @override
  Stream<ChatMessage> get incomingMessages => const Stream.empty();
  @override
  Stream<MessagesReadEvent> get messagesRead => const Stream.empty();
  @override
  Stream<BadgeUpdateEvent> get badgeUpdates => const Stream.empty();

  @override
  Future<void> connect({
    required ChatAccessTokenProvider accessTokenProvider,
  }) async {
    connectCalls++;
    if (failNextConnect) {
      failNextConnect = false;
      _set(RealtimeStatus.disconnected);
      throw StateError('connect failed');
    }
    _set(RealtimeStatus.connected);
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    _set(RealtimeStatus.disconnected);
  }

  void _set(RealtimeStatus s) {
    _status = s;
    if (!_statusController.isClosed) _statusController.add(s);
  }

  Future<void> close() => _statusController.close();
}

Future<String?> _token() async => 'stub-token';

void main() {
  late _FakePort port;

  setUp(() => port = _FakePort());
  tearDown(() => port.close());

  Future<void> pump(
    WidgetTester tester, {
    Duration grace = const Duration(seconds: 60),
    bool mounted = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: mounted
            ? ChatRealtimeHost(
                port: port,
                accessTokenProvider: _token,
                backgroundGrace: grace,
                child: const SizedBox.shrink(),
              )
            : const SizedBox.shrink(),
      ),
    );
    await tester.pump();
  }

  /// The reason this widget exists: the hub feeds every tab, so the session
  /// has to be up from shell mount — not from the first visit to Messages.
  testWidgets('opens the session on mount, before any chat screen exists', (
    tester,
  ) async {
    await pump(tester);

    expect(port.connectCalls, 1);
    expect(port.status, RealtimeStatus.connected);
  });

  testWidgets('closes the session on unmount', (tester) async {
    await pump(tester);
    await pump(tester, mounted: false);

    expect(port.disconnectCalls, 1);
  });

  // Logout replaces the whole route stack, which unmounts the shell — so the
  // teardown above is also what stops a socket carrying a stale token.
  testWidgets('a failed connect leaves the shell alive', (tester) async {
    port.failNextConnect = true;
    await pump(tester);

    expect(port.connectCalls, 1);
    expect(port.status, RealtimeStatus.disconnected);
    expect(tester.takeException(), isNull);
  });

  group('backgrounding', () {
    testWidgets('a short background does not drop the session', (
      tester,
    ) async {
      await pump(tester, grace: const Duration(seconds: 60));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 5));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(port.disconnectCalls, 0,
          reason: 'a permission dialog must not cost a reconnect');
      expect(port.connectCalls, 1);
    });

    testWidgets('past the grace window it disconnects, and resume restores it',
        (tester) async {
      await pump(tester, grace: const Duration(milliseconds: 50));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(milliseconds: 80));
      expect(port.disconnectCalls, 1);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(port.connectCalls, 2);
      expect(port.status, RealtimeStatus.connected);
    });

    // `connect()` drops the live session before opening a new one, so
    // reconnecting a healthy socket would republish the whole status cycle —
    // which ConversationCubit reads as a drop and answers with a refetch.
    testWidgets('resume on a live socket does not churn it', (tester) async {
      await pump(tester, grace: const Duration(milliseconds: 50));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(port.connectCalls, 1);
      expect(port.disconnectCalls, 0);
    });

    testWidgets('detached disconnects immediately, without waiting out grace', (
      tester,
    ) async {
      await pump(tester, grace: const Duration(seconds: 60));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.detached);
      await tester.pump();

      expect(port.disconnectCalls, 1);
    });

    // iOS enters `inactive` for routine OS transitions; reacting would
    // disconnect on every control-centre swipe.
    testWidgets('inactive and hidden are ignored', (tester) async {
      await pump(tester);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();

      expect(port.disconnectCalls, 0);
      expect(port.connectCalls, 1);
    });
  });
}
