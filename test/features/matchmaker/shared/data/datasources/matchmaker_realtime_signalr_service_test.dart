import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/shared/data/datasources/matchmaker_realtime_signalr_service.dart';
import 'package:qeran/features/matchmaker/shared/domain/entities/matchmaker_realtime_status.dart';

MatchmakerRealtimeSignalRService _svc() => MatchmakerRealtimeSignalRService(
      accessTokenProvider: () async => null,
    );

void main() {
  group('MatchmakerRealtimeSignalRService — defaults', () {
    test('initial status is disconnected', () {
      expect(_svc().status, MatchmakerRealtimeStatus.disconnected);
    });

    test('disconnect-before-connect is safe (idempotent)', () async {
      final svc = _svc();
      await svc.disconnect();
      expect(svc.status, MatchmakerRealtimeStatus.disconnected);
    });
  });

  group(
      'MatchmakerRealtimeSignalRService — lifecycle serialization '
      '(re-entrancy)', () {
    test('serialized ops run strictly sequentially — never overlap', () async {
      final svc = _svc();
      final log = <String>[];
      final gateA = Completer<void>();

      final a = svc.runSerializedForTest(() async {
        log.add('A-start');
        await gateA.future;
        log.add('A-end');
      });
      final b = svc.runSerializedForTest(() async {
        log.add('B-start');
        log.add('B-end');
      });

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(log, ['A-start']);

      gateA.complete();
      await Future.wait([a, b]);
      expect(log, ['A-start', 'A-end', 'B-start', 'B-end']);
    });

    test('a failing op surfaces to its caller AND does not stall the queue',
        () async {
      final svc = _svc();
      final log = <String>[];

      final failing = svc.runSerializedForTest(() async {
        throw StateError('boom');
      });
      await expectLater(failing, throwsA(isA<StateError>()));

      await svc.runSerializedForTest(() async => log.add('next'));
      expect(log, ['next']);
    });
  });
}
