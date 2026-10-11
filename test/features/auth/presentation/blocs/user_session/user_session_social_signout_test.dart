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

class _MockGoogle extends Mock implements GoogleSignInService {}

/// Leaving the account signs out of Google too, and a Google sign-out that
/// fails never keeps anyone signed in. Pinned before the teardown moves out of
/// the cubit (C4).
void main() {
  late _MockSecure secure;
  late _MockPrefs prefs;
  late _MockGoogle google;
  late UserSessionCubit cubit;

  setUp(() {
    secure = _MockSecure();
    prefs = _MockPrefs();
    google = _MockGoogle();
    when(() => secure.remove(any())).thenAnswer((_) async {});
    when(() => secure.clear()).thenAnswer((_) async {});
    when(() => prefs.remove(any())).thenAnswer((_) async {});
    when(() => google.signOut()).thenAnswer((_) async {});
    cubit = UserSessionCubit(
      secureStorage: secure,
      sharedPrefs: prefs,
      googleSignIn: google,
    );
  });

  tearDown(() => cubit.close());

  test('sign-out signs out of Google', () async {
    await cubit.signOut();

    verify(() => google.signOut()).called(1);
    expect(cubit.state, isA<UserSessionUnauthenticated>());
  });

  test('the deletion wipe signs out of Google', () async {
    await cubit.wipeAllLocalData();

    verify(() => google.signOut()).called(1);
    expect(cubit.state, isA<UserSessionUnauthenticated>());
  });

  test('a Google sign-out that throws still signs out', () async {
    when(() => google.signOut()).thenThrow(Exception('offline'));

    await cubit.signOut();

    verify(() => secure.remove(StorageKeys.token)).called(1);
    expect(cubit.state, isA<UserSessionUnauthenticated>());
  });
}
