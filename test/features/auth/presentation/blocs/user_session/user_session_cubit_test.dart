import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/core/services/google_sign_in_service.dart';
import 'package:qeran/features/auth/domain/entities/user_entity.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';

class MockStorageService extends Mock implements StorageService {}

class MockSharedPrefService extends Mock implements SharedPrefService {}

class MockGoogleSignInService extends Mock implements GoogleSignInService {}

void main() {
  late MockStorageService secure;
  late MockSharedPrefService prefs;
  late MockGoogleSignInService googleSignIn;
  late UserSessionCubit cubit;

  setUp(() {
    secure = MockStorageService();
    prefs = MockSharedPrefService();
    googleSignIn = MockGoogleSignInService();

    // Defaults — overridden per test as needed.
    when(() => secure.get<String>(any())).thenAnswer((_) async => null);
    when(() => prefs.get<String>(any())).thenAnswer((_) async => null);
    when(() => prefs.get<bool>(any())).thenAnswer((_) async => null);
    when(() => secure.remove(any())).thenAnswer((_) async {});
    when(() => prefs.remove(any())).thenAnswer((_) async {});
    when(() => googleSignIn.signOut()).thenAnswer((_) async {});

    cubit = UserSessionCubit(
      secureStorage: secure,
      sharedPrefs: prefs,
      googleSignIn: googleSignIn,
    );
  });

  group('hydrate', () {
    test('no token → Unauthenticated', () async {
      // secure.get returns null by default
      await cubit.hydrate();
      expect(cubit.state, isA<UserSessionUnauthenticated>());
    });

    test('empty token → Unauthenticated', () async {
      when(
        () => secure.get<String>(StorageKeys.token),
      ).thenAnswer((_) async => '');

      await cubit.hydrate();

      expect(cubit.state, isA<UserSessionUnauthenticated>());
    });

    test(
      'token + flags + name/email → Authenticated with populated user',
      () async {
        when(
          () => secure.get<String>(StorageKeys.token),
        ).thenAnswer((_) async => 'jwt-1');
        when(
          () => prefs.get<String>(StorageKeys.userId),
        ).thenAnswer((_) async => 'user-1');
        when(
          () => prefs.get<String>(StorageKeys.userName),
        ).thenAnswer((_) async => 'Ahmed');
        when(
          () => prefs.get<String>(StorageKeys.userEmail),
        ).thenAnswer((_) async => 'ahmed@example.com');
        when(
          () => prefs.get<String>(StorageKeys.userRole),
        ).thenAnswer((_) async => 'user');
        when(
          () => prefs.get<bool>(StorageKeys.isWhatsappVerified),
        ).thenAnswer((_) async => true);
        when(
          () => prefs.get<bool>(StorageKeys.finishedQuestions),
        ).thenAnswer((_) async => true);

        await cubit.hydrate();

        expect(cubit.state, isA<UserSessionAuthenticated>());
        final user = (cubit.state as UserSessionAuthenticated).user;
        expect(user.id, 'user-1');
        expect(user.name, 'Ahmed');
        expect(user.email, 'ahmed@example.com');
        expect(user.token, 'jwt-1');
        expect(user.role, 'user');
        expect(user.isPhoneVerified, true);
        expect(user.hasAnsweredQuestions, true);
      },
    );

    test('pre-migration session (no name/email in storage) → Authenticated '
        'with empty name/email', () async {
      when(
        () => secure.get<String>(StorageKeys.token),
      ).thenAnswer((_) async => 'jwt-1');
      when(
        () => prefs.get<String>(StorageKeys.userId),
      ).thenAnswer((_) async => 'user-1');
      // userName / userEmail keys deliberately unstubbed — default
      // returns null, simulating a session persisted before Option A.

      await cubit.hydrate();

      final user = (cubit.state as UserSessionAuthenticated).user;
      expect(user.id, 'user-1');
      expect(user.name, isEmpty);
      expect(user.email, isEmpty);
    });

    test('exception during read → Unauthenticated (does not throw)', () async {
      when(
        () => secure.get<String>(StorageKeys.token),
      ).thenThrow(Exception('storage offline'));

      await cubit.hydrate();

      expect(cubit.state, isA<UserSessionUnauthenticated>());
    });
  });

  group('onAuthenticated', () {
    test('emits Authenticated with the given user', () {
      const user = UserEntity(
        id: 'u-1',
        name: 'Test',
        email: 'test@example.com',
        token: 'jwt',
      );

      cubit.onAuthenticated(user);

      expect(cubit.state, equals(const UserSessionAuthenticated(user)));
    });

    test('tolerates empty token (register-new partial user)', () {
      const user = UserEntity(
        id: 'u-2',
        name: 'Pending',
        email: 'p@example.com',
        token: '',
      );

      cubit.onAuthenticated(user);

      expect(cubit.state, isA<UserSessionAuthenticated>());
      expect((cubit.state as UserSessionAuthenticated).user.token, '');
    });
  });

  group('onQuestionsAnswered', () {
    test('updates hasAnsweredQuestions, preserves other fields', () {
      const user = UserEntity(
        id: 'u-1',
        name: 'T',
        email: 't@example.com',
        token: 'jwt',
        role: 'user',
        isPhoneVerified: true,
        hasAnsweredQuestions: false,
      );
      cubit.onAuthenticated(user);

      cubit.onQuestionsAnswered();

      final updated = (cubit.state as UserSessionAuthenticated).user;
      expect(updated.hasAnsweredQuestions, true);
      expect(updated.id, 'u-1');
      expect(updated.name, 'T');
      expect(updated.email, 't@example.com');
      expect(updated.token, 'jwt');
      expect(updated.role, 'user');
      expect(updated.isPhoneVerified, true);
    });

    test('no-op when not Authenticated', () {
      // Starts in Initial.
      cubit.onQuestionsAnswered();
      expect(cubit.state, isA<UserSessionInitial>());
    });
  });

  group('signOut', () {
    test('clears the 7 session keys and emits Unauthenticated', () async {
      await cubit.signOut();

      verify(() => secure.remove(StorageKeys.token)).called(1);
      verify(() => prefs.remove(StorageKeys.userId)).called(1);
      verify(() => prefs.remove(StorageKeys.userName)).called(1);
      verify(() => prefs.remove(StorageKeys.userEmail)).called(1);
      verify(() => prefs.remove(StorageKeys.userRole)).called(1);
      verify(() => prefs.remove(StorageKeys.isWhatsappVerified)).called(1);
      verify(() => prefs.remove(StorageKeys.finishedQuestions)).called(1);
      expect(cubit.state, isA<UserSessionUnauthenticated>());
    });
  });
}
