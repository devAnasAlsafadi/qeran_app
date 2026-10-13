import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/services/google_sign_in_service.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class _MockGoogle extends Mock implements GoogleSignInService {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockApi extends Mock implements ApiConsumer {}

class _MockPrefs extends Mock implements SharedPrefService {}

class _MockSecure extends Mock implements StorageService {}

/// Run 7, item 3b, Apple's side: a failed Apple sheet carries `A-<code>`, and
/// a shipped build's log names the code. Driven through the plugin's own
/// channel, which turns `authorization-error/<code>` into Apple's exception.
const _channel = MethodChannel('com.aboutyou.dart_packages.sign_in_with_apple');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthRemoteDataSourceImpl datasource;
  setUp(() {
    datasource = AuthRemoteDataSourceImpl(
      firebaseAuth: _MockFirebaseAuth(),
      apiConsumer: _MockApi(),
      sharedPref: _MockPrefs(),
      secureStorage: _MockSecure(),
      googleSignIn: _MockGoogle(),
    );
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null),
  );

  Future<(AuthException, String)> appleFailsWith(String code) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          _channel,
          (_) async => throw PlatformException(
            code: 'authorization-error/$code',
            message: 'x',
          ),
        );
    final logs = <String>[];
    final original = debugPrint;
    debugPrint = (String? m, {int? wrapWidth}) => logs.add(m ?? '');
    try {
      await datasource.loginWithApple();
    } on AuthException catch (e) {
      return (e, logs.join());
    } finally {
      debugPrint = original;
    }
    throw StateError('expected an AuthException');
  }

  test('a closed Apple sheet: its line, A-CANCEL', () async {
    final (e, _) = await appleFailsWith('canceled');
    expect(e.message, LocaleKeys.errors_apple_sign_in_cancelled);
    expect(e.reference, 'A-CANCEL');
  });

  test('a failed Apple sheet says A-FAILED, and the log names it', () async {
    final (e, log) = await appleFailsWith('failed');
    expect(e.reference, 'A-FAILED');
    expect(log, contains('code=failed'));
  });
}
