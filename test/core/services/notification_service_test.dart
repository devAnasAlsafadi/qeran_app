import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/services/notification_service.dart';

class _MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

void main() {
  late _MockFirebaseMessaging messaging;

  setUp(() {
    messaging = _MockFirebaseMessaging();
  });

  NotificationService createService({
    List<Duration> retryDelays = const [Duration.zero, Duration.zero],
  }) {
    return NotificationService(
      messaging: messaging,
      tokenRetryDelays: retryDelays,
      delay: (_) async {},
    );
  }

  test('retries a transient token failure and returns the token', () async {
    var attempts = 0;
    when(() => messaging.getToken()).thenAnswer((_) async {
      attempts++;
      if (attempts == 1) throw StateError('SERVICE_NOT_AVAILABLE');
      return 'fcm-token';
    });

    final token = await createService().getToken();

    expect(token, 'fcm-token');
    expect(attempts, 2);
  });

  test('concurrent callers share the same token request', () async {
    final completer = Completer<String?>();
    when(() => messaging.getToken()).thenAnswer((_) => completer.future);
    final service = createService(retryDelays: const []);

    final first = service.getToken();
    final second = service.getToken();
    completer.complete('shared-token');

    expect(await first, 'shared-token');
    expect(await second, 'shared-token');
    verify(() => messaging.getToken()).called(1);
  });

  test('returns null after all retry attempts fail', () async {
    when(
      () => messaging.getToken(),
    ).thenThrow(StateError('SERVICE_NOT_AVAILABLE'));

    final token = await createService().getToken();

    expect(token, isNull);
    verify(() => messaging.getToken()).called(3);
  });
}
