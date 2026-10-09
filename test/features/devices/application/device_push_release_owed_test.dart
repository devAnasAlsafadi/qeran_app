import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/constants/storage_keys.dart';

import 'push_release_rig.dart';

/// C2: a sign-out offline can't unlink, and FCM can't delete the token — the
/// old account's pushes would keep arriving. The release stays owed (a
/// device-level marker) until FCM deletes the token: retried when the
/// connection returns and at the next start, or settled by a sign-in.
void main() {
  late PushRig rig;
  late StreamController<bool> connection;

  setUp(() async {
    rig = PushRig();
    await rig.start({...signedInPhone, StorageKeys.notifPermissionAsked: true});
    connection = StreamController<bool>();
    rig.service.retryWhenOnline(connection.stream);
  });

  tearDown(() => connection.close());

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  Future<bool?> owed() => rig.prefs.get<bool>(StorageKeys.pushReleaseOwed);

  /// Signs out with no network: the unlink and FCM's delete both fail.
  Future<void> signOutOffline() async {
    when(
      () => rig.unlink(token: any(named: 'token')),
    ).thenAnswer((_) async => throw Exception('offline'));
    when(
      rig.notifications.deleteToken,
    ).thenAnswer((_) async => throw Exception('offline'));
    await rig.service.releasePush();
    await settle();
    rig.calls.clear();
    when(
      rig.notifications.deleteToken,
    ).thenAnswer((_) async => rig.calls.add('delete'));
  }

  test('offline: the release stays owed; the token keys still go', () async {
    await signOutOffline();

    expect(await owed(), isTrue);
    expect(await rig.prefs.get<String>(StorageKeys.lastRegisteredFcm), isNull);
    expect(await rig.prefs.get<bool>(StorageKeys.deviceRegistered), isNull);
  });

  test(
    'back online: deleted, a new token registered unlinked, nothing owed',
    () async {
      await signOutOffline();

      connection.add(true);
      await settle();

      expect(rig.calls, ['delete', 'register $newToken']);
      expect(await owed(), isNull);
    },
  );

  test('going offline again does not retry', () async {
    await signOutOffline();

    connection.add(false);
    await settle();

    expect(rig.calls, isEmpty);
    expect(await owed(), isTrue);
  });

  test('the next start finishes it before anything else', () async {
    await signOutOffline();

    await rig.service.bootstrap();

    expect(rig.calls.take(2), ['delete', 'register $newToken']);
    expect(await owed(), isNull);
  });

  test('a sign-in first settles it: no second renewal', () async {
    await signOutOffline();

    await rig.service.linkSilently();
    connection.add(true);
    await settle();

    expect(rig.calls, ['link $newToken']);
    expect(await owed(), isNull);
  });
}
