import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/services/google_sign_in_service.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/core/state/account_scope.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockStorage extends Mock implements StorageService {}

class _MockGoogleSignIn extends Mock implements GoogleSignInService {}

/// C1: a start with no session forgets the account prefs. `allowBackup` is
/// the platform default and there are no backup rules, so an Android restore
/// can bring the prefs back without the token — the next account to sign in
/// would inherit them. The device's own keys stay.
void main() {
  late SharedPreferences prefs;
  late _MockStorage secure;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      StorageKeys.userId: 'old-1',
      StorageKeys.userRole: 'Moderator',
      StorageKeys.isWhatsappVerified: true,
      StorageKeys.finishedQuestions: true,
      StorageKeys.pendingUserId: 'old-1',
      StorageKeys.seenOnboarding: true,
      StorageKeys.latestFcmToken: 'fcm-1',
      StorageKeys.deviceRegistered: true,
    });
    prefs = await SharedPreferences.getInstance();
    secure = _MockStorage();
  });

  Future<(UserSessionCubit, List<String>)> hydrate({String? token}) async {
    when(
      () => secure.get<String>(StorageKeys.token),
    ).thenAnswer((_) async => token);
    final forgotten = <String>[];
    final scope = AccountScope()..hold('cache', forgotten.add);
    final cubit = UserSessionCubit(
      secureStorage: secure,
      sharedPrefs: SharedPrefService(prefs),
      googleSignIn: _MockGoogleSignIn(),
      accountScope: scope,
    );
    await cubit.hydrate();
    return (cubit, forgotten);
  }

  test('no token: the account prefs go, the device keys stay', () async {
    final (cubit, forgotten) = await hydrate();

    expect(cubit.state, isA<UserSessionUnauthenticated>());
    for (final key in StorageKeys.accountKeys) {
      expect(prefs.containsKey(key), isFalse, reason: key);
    }
    expect(prefs.getBool(StorageKeys.seenOnboarding), isTrue);
    expect(prefs.getString(StorageKeys.latestFcmToken), 'fcm-1');
    expect(prefs.getBool(StorageKeys.deviceRegistered), isTrue);
    expect(forgotten, ['cache'], reason: 'the app-scoped holders forget too');
    await cubit.close();
  });

  test('a session keeps them', () async {
    final (cubit, forgotten) = await hydrate(token: 'jwt');

    expect(cubit.state, isA<UserSessionAuthenticated>());
    expect(prefs.getString(StorageKeys.userId), 'old-1');
    expect(forgotten, isEmpty);
    await cubit.close();
  });
}
