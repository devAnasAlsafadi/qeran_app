import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/services/google_sign_in_service.dart';
import 'package:qeran/features/auth/domain/entities/user_entity.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';

import '../../../../../core/memory_storage.dart';

class _MockPrefs extends Mock implements SharedPrefService {}

class _MockGoogle extends Mock implements GoogleSignInService {}

/// A password change's new token becomes the session's: stored, for the
/// requests, and on the signed-in user, for the images. Signed out by then,
/// it is dropped — stored, it would sign the account back in at next start.
void main() {
  late MemoryStorage secure;
  late UserSessionCubit cubit;

  setUp(() {
    secure = MemoryStorage()..values[StorageKeys.token] = 'jwt-1';
    cubit = UserSessionCubit(
      secureStorage: secure,
      sharedPrefs: _MockPrefs(),
      googleSignIn: _MockGoogle(),
    );
  });

  tearDown(() => cubit.close());

  test('signed in: stored, and the user\'s token from now on', () async {
    cubit.onAuthenticated(
      const UserEntity(id: 'u-1', name: 'N', email: 'e', token: 'jwt-1'),
    );

    await cubit.adoptToken('jwt-2');

    expect(secure.values[StorageKeys.token], 'jwt-2');
    final user = (cubit.state as UserSessionAuthenticated).user;
    expect(user.token, 'jwt-2');
    expect(user.id, 'u-1');
  });

  test('signed out meanwhile: dropped', () async {
    secure.values.remove(StorageKeys.token);

    await cubit.adoptToken('jwt-2');

    expect(secure.values.containsKey(StorageKeys.token), isFalse);
  });
}
