import 'package:firebase_auth/firebase_auth.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/services/google_sign_in_service.dart';
import 'package:qeran/core/state/account_scope.dart';
import 'package:qeran/features/auth/presentation/auth_form_memo.dart';

/// What leaving an account clears outside secure storage, for
/// `UserSessionCubit`: its sign-out, the deletion wipe, a session-less start
/// and a different account signing in.
class AccountTeardown {
  AccountTeardown({
    required SharedPrefService sharedPrefs,
    required GoogleSignInService googleSignIn,
    required AuthFormMemo formMemo,
    required AccountScope accountScope,
  }) : _sharedPrefs = sharedPrefs,
       _googleSignIn = googleSignIn,
       _formMemo = formMemo,
       _accountScope = accountScope;

  final SharedPrefService _sharedPrefs;
  final GoogleSignInService _googleSignIn;

  /// What the auth forms carried between login and register. It outlives both
  /// screens, so tearing the session down has to reach it explicitly.
  final AuthFormMemo _formMemo;

  /// Everything app-scoped that belongs to the account: forgotten whenever
  /// the account changes, so the next one starts from nothing.
  final AccountScope _accountScope;

  /// Everything of the account outside secure storage. Runs after the token
  /// is gone, so a screen that reloads on the way out asks as nobody; a
  /// request already in flight is dropped by its holder when it lands.
  ///
  /// The auth-form memo goes too: it is app-scoped and outlives the screens
  /// that filled it, so the NEXT person to open login would otherwise be
  /// greeted by the previous account's email.
  Future<void> forgetAccount() async {
    _formMemo.clear();
    for (final key in StorageKeys.accountKeys) {
      await _sharedPrefs.remove(key);
    }
    forgetAppState();
  }

  /// The app-scoped state alone: a different account signing in.
  void forgetAppState() => _accountScope.forgetAccount();

  /// Google and Firebase. Best effort: a failure never keeps anyone signed in.
  Future<void> clearSocialSessions() async {
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      AppLogger.warning('Social sign-out error: $e', tag: 'SESSION');
    }
  }
}
