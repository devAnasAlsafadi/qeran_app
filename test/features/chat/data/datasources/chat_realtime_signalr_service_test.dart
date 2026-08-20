import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/chat/data/datasources/chat_realtime_signalr_service.dart';
import 'package:qeran/features/chat/domain/entities/realtime_status.dart';

void main() {
  group('ChatRealtimeSignalRService — defaults', () {
    test('initial status is disconnected', () {
      final svc = ChatRealtimeSignalRService();
      expect(svc.status, RealtimeStatus.disconnected);
    });

    test('disconnect-before-connect is safe (idempotent)', () async {
      final svc = ChatRealtimeSignalRService();
      // Must not throw. Status stays disconnected (no transition emitted
      // because we never moved away from it).
      await svc.disconnect();
      expect(svc.status, RealtimeStatus.disconnected);
    });
  });

  group('ChatRealtimeSignalRService — lifecycle serialization (re-entrancy)',
      () {
    test('serialized ops run strictly sequentially — never overlap', () async {
      final svc = ChatRealtimeSignalRService();
      final log = <String>[];
      final gateA = Completer<void>();

      // Op A starts, then blocks — models a connect() whose start() is still
      // in-flight.
      final a = svc.runSerializedForTest(() async {
        log.add('A-start');
        await gateA.future;
        log.add('A-end');
      });
      // Op B is enqueued while A is still running — models a disconnect()
      // arriving mid-start. It must NOT begin until A fully settles (so a
      // stop() can never run against a half-started connection).
      final b = svc.runSerializedForTest(() async {
        log.add('B-start');
        log.add('B-end');
      });

      // Let the event loop spin; B must still be blocked behind A.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(log, ['A-start']);

      gateA.complete();
      await Future.wait([a, b]);
      // Strict, non-overlapping order.
      expect(log, ['A-start', 'A-end', 'B-start', 'B-end']);
    });

    test('a failing op surfaces to its caller AND does not stall the queue',
        () async {
      final svc = ChatRealtimeSignalRService();
      final log = <String>[];

      final failing = svc.runSerializedForTest(() async {
        throw StateError('boom');
      });
      await expectLater(failing, throwsA(isA<StateError>()));

      // A later op (e.g. the next connect) still runs.
      await svc.runSerializedForTest(() async => log.add('next'));
      expect(log, ['next']);
    });
  });

  group('ChatRealtimeSignalRService — incoming message dispatch', () {
    test('valid ReceiveMessage args emit a ChatMessage on the stream',
        () async {
      final svc = ChatRealtimeSignalRService();
      // Subscribe BEFORE dispatching so the broadcast stream delivers.
      final received = svc.incomingMessages.first;
      svc.onReceiveMessageForTest([
        {
          'id': 200,
          'conversationId': 42,
          'senderId': 'mm',
          'senderName': 'أم محمد',
          'content': 'hi',
          'sharedProfile': null,
          'isRead': false,
          'sentAt': '2026-05-21T10:30:00Z',
        }
      ]);
      final msg = await received.timeout(const Duration(seconds: 1));
      expect(msg.serverId, 200);
      expect(msg.content, 'hi');
    });

    test('malformed ReceiveMessage args do NOT emit', () async {
      final svc = ChatRealtimeSignalRService();
      var emitted = false;
      final sub = svc.incomingMessages.listen((_) => emitted = true);
      svc.onReceiveMessageForTest(null);
      svc.onReceiveMessageForTest([]);
      svc.onReceiveMessageForTest(['not a map']);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();
      expect(emitted, isFalse);
    });
  });

  group('ChatRealtimeSignalRService — messages-read dispatch', () {
    test('valid MessagesRead args emit an event on the stream', () async {
      final svc = ChatRealtimeSignalRService();
      final received = svc.messagesRead.first;
      svc.onMessagesReadForTest([
        {
          'conversationId': 42,
          'readByUserId': 'mm-guid',
          'readAt': '2026-05-21T10:30:00Z',
        }
      ]);
      final event = await received.timeout(const Duration(seconds: 1));
      expect(event.conversationId, 42);
      expect(event.readByUserId, 'mm-guid');
    });

    test('malformed MessagesRead args do NOT emit', () async {
      final svc = ChatRealtimeSignalRService();
      var emitted = false;
      final sub = svc.messagesRead.listen((_) => emitted = true);
      svc.onMessagesReadForTest(null);
      svc.onMessagesReadForTest([]);
      svc.onMessagesReadForTest([42]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();
      expect(emitted, isFalse);
    });
  });

  group('ChatRealtimeSignalRService — badge dispatch', () {
    test('valid BadgeUpdated args emit an event on the stream', () async {
      final svc = ChatRealtimeSignalRService();
      final received = svc.badgeUpdates.first;
      svc.onBadgeUpdatedForTest([
        {'tab': 'likesUnread', 'count': 3},
      ]);
      final event = await received.timeout(const Duration(seconds: 1));
      expect(event.tab, 'likesUnread');
      expect(event.count, 3);
    });

    test('malformed BadgeUpdated args do NOT emit', () async {
      final svc = ChatRealtimeSignalRService();
      var emitted = false;
      final sub = svc.badgeUpdates.listen((_) => emitted = true);
      svc.onBadgeUpdatedForTest(null);
      svc.onBadgeUpdatedForTest([]);
      svc.onBadgeUpdatedForTest([42]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();
      expect(emitted, isFalse);
    });
  });

  group('ChatRealtimeSignalRService — dispose', () {
    test('dispose closes controllers without throwing', () async {
      final svc = ChatRealtimeSignalRService();
      // Subscribe + dispatch one event so the stream isn't pristine.
      final received = svc.incomingMessages.first;
      svc.onReceiveMessageForTest([
        {
          'id': 1,
          'conversationId': 1,
          'senderId': 's',
          'senderName': 's',
          'content': 'c',
          'sharedProfile': null,
          'isRead': true,
          'sentAt': '2026-05-21T10:30:00Z',
        }
      ]);
      await received;

      await svc.dispose();
      // After dispose, further dispatches must NOT throw (controllers
      // are closed → we early-return on `isClosed`).
      svc.onReceiveMessageForTest([
        {
          'id': 2,
          'conversationId': 1,
          'senderId': 's',
          'senderName': 's',
          'content': 'c',
          'sharedProfile': null,
          'isRead': true,
          'sentAt': '2026-05-21T10:30:00Z',
        }
      ]);
    });
  });
}
