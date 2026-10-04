import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/errors/errors.dart';

import 'push_release_rig.dart';

/// Sign-out stops this device's push for the account leaving (A1): the
/// server's unlink, waited for briefly, then the FCM token deleted on the
/// device and a new one registered, linked to no one.
void main() {
  late PushRig rig;

  setUp(() async {
    rig = PushRig();
    await rig.start();
  });

  /// The background renewal, given time to finish.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  void unlinkAnswers(Future<Either<Failure, Unit>> Function() answer) => when(
    () => rig.unlink(token: any(named: 'token')),
  ).thenAnswer((_) => answer());

  test('unlinks the token, deletes it with FCM, then registers a new one — '
      'linked to no one', () async {
    await rig.service.releasePush();
    await settle();

    expect(rig.calls, ['unlink $oldToken', 'delete', 'register $newToken']);
    expect(await rig.prefs.get<String>(StorageKeys.latestFcmToken), newToken);
    expect(
      await rig.prefs.get<String>(StorageKeys.lastRegisteredFcm),
      newToken,
    );
    expect(await rig.prefs.get<bool>(StorageKeys.deviceRegistered), isTrue);
  });

  test('no token on the device: nothing to release, none fetched', () async {
    await rig.start({});

    await rig.service.releasePush();
    await settle();

    expect(rig.calls, isEmpty);
    verifyNever(rig.notifications.getToken);
  });

  test('the server refusing the unlink: the token is renewed anyway', () async {
    unlinkAnswers(() async => const Left(ServerFailure(message: 'nope')));

    await rig.service.releasePush();
    await settle();

    expect(rig.calls, ['delete', 'register $newToken']);
  });

  test('an unlink that throws: never past here, the token renewed', () async {
    unlinkAnswers(() async => throw Exception('x'));

    await expectLater(rig.service.releasePush(), completes);
    await settle();

    expect(rig.calls, ['delete', 'register $newToken']);
  });

  testWidgets('an unlink that never answers holds sign-out 3 s, no more', (
    tester,
  ) async {
    unlinkAnswers(() => Completer<Either<Failure, Unit>>().future);
    var released = false;
    unawaited(rig.service.releasePush().then((_) => released = true));

    await tester.pump(const Duration(milliseconds: 2900));
    expect(released, isFalse);
    expect(rig.calls, isEmpty);

    await tester.pump(const Duration(milliseconds: 200));
    expect(released, isTrue);
    expect(rig.calls, ['delete', 'register $newToken']);
  });

  testWidgets('FCM out of reach: 10 s for the delete, then the markers go and '
      'no token is fetched', (tester) async {
    when(
      rig.notifications.deleteToken,
    ).thenAnswer((_) => Completer<void>().future);
    await rig.service.releasePush();

    await tester.pump(const Duration(seconds: 9));
    expect(await rig.prefs.get<String>(StorageKeys.latestFcmToken), oldToken);

    await tester.pump(const Duration(seconds: 2));
    expect(await rig.prefs.get<String>(StorageKeys.latestFcmToken), isNull);
    expect(await rig.prefs.get<String>(StorageKeys.lastRegisteredFcm), isNull);
    expect(await rig.prefs.get<bool>(StorageKeys.deviceRegistered), isNull);
    verifyNever(rig.notifications.getToken);
  });

  test('a sign-in during the renewal waits for it, and links the new token, '
      'never the deleted one', () async {
    final deleted = Completer<void>();
    when(rig.notifications.deleteToken).thenAnswer((_) => deleted.future);
    await rig.service.releasePush();

    final signIn = rig.service.linkSilently();
    await settle();
    expect(rig.calls.where((c) => c.startsWith('link')), isEmpty);

    deleted.complete();
    await signIn;
    expect(rig.calls, [
      'unlink $oldToken',
      'register $newToken',
      'link $newToken',
    ]);
  });
}
