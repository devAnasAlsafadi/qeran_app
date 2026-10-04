import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/services/google_sign_in_service.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';

class _MockSecure extends Mock implements StorageService {}

class _MockPrefs extends Mock implements SharedPrefService {}

class _MockGoogleSignIn extends Mock implements GoogleSignInService {}

/// Sign-out stops this device's push for the account leaving (A1): while the
/// token is still stored, and never at the cost of the sign-out itself.
void main() {
  late _MockSecure secure;
  late _MockPrefs prefs;
  late _MockGoogleSignIn googleSignIn;
  final log = <String>[];

  setUp(() {
    log.clear();
    secure = _MockSecure();
    prefs = _MockPrefs();
    googleSignIn = _MockGoogleSignIn();
    when(() => secure.remove(any())).thenAnswer((_) async => log.add('token'));
    when(secure.clear).thenAnswer((_) async => log.add('secure'));
    when(() => prefs.remove(any())).thenAnswer((_) async => log.add('prefs'));
    when(googleSignIn.signOut).thenAnswer((_) async {});
  });

  UserSessionCubit cubitWith(Future<void> Function() releasePush) =>
      UserSessionCubit(
        secureStorage: secure,
        sharedPrefs: prefs,
        googleSignIn: googleSignIn,
        releasePush: releasePush,
      );

  test('push is released first, while the token is still stored', () async {
    final cubit = cubitWith(() async => log.add('push'));

    await cubit.signOut();

    expect(log.take(2), ['push', 'token']);
    expect(cubit.state, isA<UserSessionUnauthenticated>());
  });

  test('a release that fails still signs out', () async {
    final cubit = cubitWith(() async => throw Exception('offline'));

    await cubit.signOut();

    verify(() => secure.remove(StorageKeys.token)).called(1);
    expect(cubit.state, isA<UserSessionUnauthenticated>());
  });

  test('one that throws before it starts still signs out', () async {
    final cubit = cubitWith(() => throw StateError('not registered'));

    await cubit.signOut();

    verify(() => secure.remove(StorageKeys.token)).called(1);
    expect(cubit.state, isA<UserSessionUnauthenticated>());
  });

  test('a deleted account is wiped without it: the delete unlinks first, '
      'and nothing is linked to an account that is gone', () async {
    final cubit = cubitWith(() async => log.add('push'));

    await cubit.wipeAllLocalData();

    expect(log, isNot(contains('push')));
    expect(cubit.state, isA<UserSessionUnauthenticated>());
  });
}
