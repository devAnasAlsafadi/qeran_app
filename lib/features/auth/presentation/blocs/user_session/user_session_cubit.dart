import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/core/services/google_sign_in_service.dart';
import 'package:qeran/core/state/account_scope.dart';
import 'package:qeran/features/auth/domain/entities/user_entity.dart';
import 'package:qeran/features/auth/presentation/auth_form_memo.dart';
import 'user_session_state.dart';

/// App-scoped holder for the currently signed-in user.
///
/// Hydrated once from storage while the branded splash is visible, then mutated by
/// the auth blocs (`LoginBloc`, `RegisterBloc`, `WhatsappBloc`) and
/// `OathCubit` after their respective success branches. Provided at the
/// root of the widget tree via `BlocProvider.value` so any descendant can
/// observe the session reactively.
///
/// Deviates from §2 of `CLAUDE.md` (factory for Cubits): this cubit holds
/// app-lifetime state and is registered as a lazy singleton in DI.
class UserSessionCubit extends Cubit<UserSessionState>
    with SafeEmit<UserSessionState> {
  final StorageService _secureStorage;
  final SharedPrefService _sharedPrefs;
  final GoogleSignInService _googleSignIn;

  /// What the auth forms carried between login and register. It outlives both
  /// screens, so tearing the session down has to reach it explicitly.
  final AuthFormMemo _formMemo;

  /// Everything app-scoped that belongs to the account: forgotten whenever
  /// the account changes, so the next one starts from nothing.
  final AccountScope _accountScope;

  /// [formMemo] defaults to the app-scoped instance; a test that has not booted
  /// the container gets an isolated one rather than a lookup crash. The app
  /// passes its [accountScope]; a test that doesn't gets an empty one.
  UserSessionCubit({
    required StorageService secureStorage,
    required SharedPrefService sharedPrefs,
    required GoogleSignInService googleSignIn,
    AuthFormMemo? formMemo,
    AccountScope? accountScope,
  }) : _secureStorage = secureStorage,
       _sharedPrefs = sharedPrefs,
       _googleSignIn = googleSignIn,
       _formMemo = formMemo ?? resolveAuthFormMemo(),
       _accountScope = accountScope ?? AccountScope(),
       super(const UserSessionInitial());

  /// Synchronous accessor for call sites that can't await a stream.
  UserEntity? get currentUser {
    final s = state;
    return s is UserSessionAuthenticated ? s.user : null;
  }

  /// Reads storage once on cold start to reconstruct the session.
  ///
  /// Rehydrates the keys `_persistAuthSession` writes: token, userId,
  /// userName, userEmail, role, and flags. Sessions written before these
  /// keys existed will read back as empty strings — the next sign-in
  /// persists them. Photo URL, gender, birthdate, etc. remain owned by
  /// the profile feature.
  Future<void> hydrate() async {
    emit(const UserSessionLoading());
    try {
      final token = await _secureStorage.get<String>(StorageKeys.token);
      if (token == null || token.isEmpty) {
        emit(const UserSessionUnauthenticated());
        return;
      }

      final id = await _sharedPrefs.get<String>(StorageKeys.userId) ?? '';
      final name = await _sharedPrefs.get<String>(StorageKeys.userName) ?? '';
      final email = await _sharedPrefs.get<String>(StorageKeys.userEmail) ?? '';
      final role = await _sharedPrefs.get<String>(StorageKeys.userRole);
      final phoneVerified = await _sharedPrefs.get<bool>(
        StorageKeys.isWhatsappVerified,
      );
      final answered = await _sharedPrefs.get<bool>(
        StorageKeys.finishedQuestions,
      );

      emit(
        UserSessionAuthenticated(
          UserEntity(
            id: id,
            name: name,
            email: email,
            token: token,
            role: role,
            isPhoneVerified: phoneVerified,
            hasAnsweredQuestions: answered,
          ),
        ),
      );
    } catch (e, s) {
      AppLogger.error(
        'UserSession hydrate failed',
        error: e,
        stack: s,
        tag: 'SESSION',
      );
      emit(const UserSessionUnauthenticated());
    }
  }

  /// Called by auth blocs after a sign-in succeeds. Tolerates an empty
  /// token — `register-new` returns a partial user without one.
  ///
  /// A different account than the one held (or the first since the app
  /// opened) forgets the app-scoped state first: nothing the previous account
  /// left can reach the new one. The same account confirmed again (the OTP
  /// step after registration) keeps it.
  void onAuthenticated(UserEntity user) {
    if (currentUser?.id != user.id) _accountScope.forgetAccount();
    emit(UserSessionAuthenticated(user));
  }

  /// Called by `OathCubit` after `Questions/submit` succeeds. Flips
  /// `hasAnsweredQuestions` on the current user without touching anything
  /// else. No-op when there's no authenticated user.
  void onQuestionsAnswered() {
    final current = state;
    if (current is! UserSessionAuthenticated) return;
    final u = current.user;
    emit(
      UserSessionAuthenticated(
        UserEntity(
          id: u.id,
          name: u.name,
          email: u.email,
          phoneNumber: u.phoneNumber,
          photoUrl: u.photoUrl,
          token: u.token,
          role: u.role,
          isPhoneVerified: u.isPhoneVerified,
          hasAnsweredQuestions: true,
        ),
      ),
    );
  }

  /// Clears the persisted session and emits `Unauthenticated`. Reached from
  /// the logout action on `ProfileScreen` and `MatchmakerAccountScreen`.
  ///
  /// Forgets the whole account, as a delete does short of secure storage:
  /// the token, every account-level pref (a half-done questionnaire, the
  /// chosen gender and the read marks included), what the auth forms
  /// remembered, and the app-scoped state ([_forgetAccount]).
  Future<void> signOut() async {
    await _clearSocialSessions();
    await _secureStorage.remove(StorageKeys.token);
    await _forgetAccount();
    emit(const UserSessionUnauthenticated());
  }

  /// Full local wipe for a PERMANENT account deletion, after the server's
  /// `DELETE /api/Profile` succeeds: [signOut], with secure storage cleared
  /// wholesale (only sensitive auth lives there). DEVICE-level prefs survive
  /// both — onboarding, the notification permission, the FCM registration
  /// markers and the language; [StorageKeys.accountKeys] lists what goes.
  Future<void> wipeAllLocalData() async {
    await _clearSocialSessions();
    // Secure: only the JWT (+ any sensitive auth) — safe to clear wholesale.
    await _secureStorage.clear();
    await _forgetAccount();
    AppLogger.info('Local data wiped (account deletion)', tag: 'SESSION');
    emit(const UserSessionUnauthenticated());
  }

  /// Everything of the account outside secure storage. Runs after the token
  /// is gone, so a screen that reloads on the way out asks as nobody; a
  /// request already in flight is dropped by its holder when it lands.
  ///
  /// The auth-form memo goes too: it is app-scoped and outlives the screens
  /// that filled it, so the NEXT person to open login would otherwise be
  /// greeted by the previous account's email.
  Future<void> _forgetAccount() async {
    _formMemo.clear();
    for (final key in StorageKeys.accountKeys) {
      await _sharedPrefs.remove(key);
    }
    _accountScope.forgetAccount();
  }

  Future<void> _clearSocialSessions() async {
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      AppLogger.warning('Social sign-out error: $e', tag: 'SESSION');
    }
  }
}
