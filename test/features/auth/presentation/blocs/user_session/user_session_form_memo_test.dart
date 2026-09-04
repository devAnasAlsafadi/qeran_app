import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/services/google_sign_in_service.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/features/auth/presentation/auth_form_memo.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';

class _MockStorage extends Mock implements StorageService {}

class _MockPrefs extends Mock implements SharedPrefService {}

class _MockGoogleSignIn extends Mock implements GoogleSignInService {}

/// [AuthFormMemo] is app-scoped so the login and register screens can hand the
/// email and username to each other. That lifetime is the feature, and it is
/// also why tearing the session down has to reach it by hand: the memo outlives
/// both screens and neither one runs on the way out.
///
/// Without this, signing out left the next person to open the app looking at
/// the previous account's email — and a PERMANENT account deletion left it
/// there too, which is the account still being on the device after the member
/// asked for it to be gone.
void main() {
  late _MockStorage secure;
  late _MockPrefs prefs;
  late _MockGoogleSignIn googleSignIn;
  late AuthFormMemo memo;
  late UserSessionCubit cubit;

  setUp(() {
    secure = _MockStorage();
    prefs = _MockPrefs();
    googleSignIn = _MockGoogleSignIn();
    when(() => secure.remove(any())).thenAnswer((_) async {});
    when(() => secure.clear()).thenAnswer((_) async {});
    when(() => prefs.remove(any())).thenAnswer((_) async {});
    when(() => googleSignIn.signOut()).thenAnswer((_) async {});

    memo = AuthFormMemo()
      ..rememberEmail('previous@account.com')
      ..rememberDisplayName('سارة');

    cubit = UserSessionCubit(
      secureStorage: secure,
      sharedPrefs: prefs,
      googleSignIn: googleSignIn,
      formMemo: memo,
    );
  });

  tearDown(() => cubit.close());

  /// The memo really is carrying something, so an assertion that it is empty
  /// afterwards can actually fail.
  void expectPrimed() {
    expect(memo.email, 'previous@account.com');
    expect(memo.displayName, 'سارة');
  }

  test('signing out drops what the auth forms remembered', () async {
    expectPrimed();

    await cubit.signOut();

    expect(
      memo.email,
      isEmpty,
      reason: 'the next person to open login sees the previous account email',
    );
    expect(memo.displayName, isEmpty);
  });

  test('a permanent account deletion drops it too', () async {
    expectPrimed();

    await cubit.wipeAllLocalData();

    expect(
      memo.email,
      isEmpty,
      reason: 'the account was deleted and its email is still on the device',
    );
    expect(memo.displayName, isEmpty);
  });
}
