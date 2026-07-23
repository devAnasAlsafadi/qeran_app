import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/core/services/google_sign_in_service.dart';
import 'package:qeran/features/auth/domain/entities/user_entity.dart';
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

  UserSessionCubit({
    required StorageService secureStorage,
    required SharedPrefService sharedPrefs,
    required GoogleSignInService googleSignIn,
  }) : _secureStorage = secureStorage,
       _sharedPrefs = sharedPrefs,
       _googleSignIn = googleSignIn,
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
  void onAuthenticated(UserEntity user) {
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

  /// Clears the persisted session and emits `Unauthenticated`. Stubbed for
  /// the future logout flow — not yet wired into any UI.
  Future<void> signOut() async {
    await _clearSocialSessions();
    await _secureStorage.remove(StorageKeys.token);
    await _sharedPrefs.remove(StorageKeys.userId);
    await _sharedPrefs.remove(StorageKeys.userName);
    await _sharedPrefs.remove(StorageKeys.userEmail);
    await _sharedPrefs.remove(StorageKeys.userRole);
    await _sharedPrefs.remove(StorageKeys.isWhatsappVerified);
    await _sharedPrefs.remove(StorageKeys.finishedQuestions);
    emit(const UserSessionUnauthenticated());
  }

  /// Full local wipe for a PERMANENT account deletion — stronger than
  /// [signOut]. Clears every account/session value, then emits
  /// `Unauthenticated`. Used by the delete-account flow after the server
  /// `DELETE /api/Profile` succeeds.
  ///
  /// Secure storage is cleared wholesale (only sensitive auth lives there).
  /// Shared-prefs are wiped by an EXPLICIT account-key list (Approach A) so
  /// DEVICE-level keys survive the delete and are deliberately PRESERVED:
  /// `seen_onboarding`, `notif_permission_asked`, `latest_fcm_token`,
  /// `device_registered`, `last_registered_fcm`, `last_registered_lang`, and
  /// easy_localization's `__locale__` (the user's language).
  ///
  /// ⚠️ Keep in sync: a NEW account-level key in [StorageKeys] must be added to
  /// [_accountPrefKeys] below (see the note in StorageKeys).
  Future<void> wipeAllLocalData() async {
    await _clearSocialSessions();
    // Secure: only the JWT (+ any sensitive auth) — safe to clear wholesale.
    await _secureStorage.clear();
    for (final key in _accountPrefKeys) {
      await _sharedPrefs.remove(key);
    }
    AppLogger.info('Local data wiped (account deletion)', tag: 'SESSION');
    emit(const UserSessionUnauthenticated());
  }

  Future<void> _clearSocialSessions() async {
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      AppLogger.warning('Social sign-out error: $e', tag: 'SESSION');
    }
  }

  /// Account/session shared-prefs keys removed on a permanent delete. Device-
  /// level keys are intentionally absent here (preserved across the delete).
  static const List<String> _accountPrefKeys = [
    // Session / identity
    StorageKeys.userId,
    StorageKeys.userName,
    StorageKeys.userEmail,
    StorageKeys.userRole,
    StorageKeys.firebaseUid,
    // Account state / profile
    StorageKeys.isWhatsappVerified,
    StorageKeys.finishedQuestions,
    StorageKeys.gender,
    StorageKeys.signedOath,
    StorageKeys.questionnaireDraft,
    StorageKeys.uploadedPhotos,
    StorageKeys.pendingUserId,
    // Notification read-state heuristics (account-level)
    StorageKeys.notifLastSeenId,
    StorageKeys.matchmakerNotifLastSeenCount,
    // Account-LINK marker only — the device REGISTRATION markers are preserved
    // so the next login re-links cleanly without a redundant re-register.
    StorageKeys.lastLinkedFcm,
  ];
}
