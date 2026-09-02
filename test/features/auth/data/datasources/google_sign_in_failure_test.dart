import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/app_logger.dart';
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

/// What a failed Google sign-in tells us, and what it tells the user.
///
/// The shipped build discarded the real cause entirely — every [AppLogger]
/// level is gated on `kDebugMode`, so the code and description of a
/// [GoogleSignInException] reached nothing at all in release. Diagnosing the
/// iOS failure needed a source dig that this makes unnecessary next time.

/// Captures whatever [AppLogger.releaseDiagnostic] writes, by swapping the
/// `debugPrint` hook the way Flutter intends.
List<String> _captureLogs(void Function() body) {
  final written = <String>[];
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) written.add(message);
  };
  try {
    body();
  } finally {
    debugPrint = original;
  }
  return written;
}

void main() {
  group('the release-visible diagnostic', () {
    test('is not gated on debug, the way every other level is', () {
      // ⚠️ Read as SOURCE, deliberately. `flutter test` runs in debug, so
      // kDebugMode is true here and a debug-gated logger behaves identically
      // to a release-visible one — no behavioural test can tell them apart.
      // Re-adding the guard is precisely the bug this sub-step removes, and
      // it survived every behavioural assertion until this check existed.
      final source = File('lib/core/app_logger.dart').readAsStringSync();
      // Everything after the signature. `releaseDiagnostic` is the last
      // member of the class, so the tail IS its body.
      final parts = source.split('static void releaseDiagnostic');
      expect(parts.length, 2, reason: 'releaseDiagnostic is gone');
      final body = parts.last;

      expect(
        body,
        isNot(contains('_isDebug')),
        reason: 'releaseDiagnostic must write in release builds too',
      );
    });

    test('writes the message it is given', () {
      final written = _captureLogs(
        () => AppLogger.releaseDiagnostic('something broke', tag: 'AUTH'),
      );

      expect(written, isNotEmpty);
    });

    test('carries the message so the cause is readable', () {
      final written = _captureLogs(
        () => AppLogger.releaseDiagnostic('clientConfigurationError'),
      );

      expect(written.single, contains('clientConfigurationError'));
    });

    test('carries the tag so it can be filtered out of a busy device log', () {
      final written = _captureLogs(
        () => AppLogger.releaseDiagnostic('anything', tag: 'AUTH'),
      );

      expect(written.single, contains('AUTH'));
    });
  });

  group('what a real failure produces', () {
    late _MockGoogle google;
    late AuthRemoteDataSourceImpl datasource;

    setUp(() {
      google = _MockGoogle();
      datasource = AuthRemoteDataSourceImpl(
        firebaseAuth: _MockFirebaseAuth(),
        apiConsumer: _MockApi(),
        sharedPref: _MockPrefs(),
        secureStorage: _MockSecure(),
        googleSignIn: google,
      );
    });

    /// Drives the REAL `loginWithGoogle` catch, rather than a copy of it here.
    /// A copy would keep passing while the datasource was mutated underneath.
    Future<List<String>> failWith(Object error) async {
      when(() => google.authenticate()).thenThrow(error);
      final written = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) written.add(message);
      };
      try {
        await datasource.loginWithGoogle();
        fail('expected loginWithGoogle to throw');
      } on AuthException catch (e) {
        written.add('THROWN:${e.message}');
      } finally {
        debugPrint = original;
      }
      return written;
    }

    test('names the failure code, which is what identifies the cause', () async {
      final written = await failWith(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
          description: 'no client id',
        ),
      );

      // `clientConfigurationError` is precisely the code a missing client
      // configuration produces — the iOS failure being chased.
      expect(written.join(), contains('clientConfigurationError'));
      expect(written.join(), contains('no client id'));
    });

    test('a cancelled sign-in is distinguishable from a broken one', () async {
      final written = await failWith(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
          description: 'user backed out',
        ),
      );

      // Without the code, a user tapping Cancel and a misconfigured app look
      // identical in the log — both just "Google sign-in failed".
      expect(written.join(), contains('canceled'));
    });

    test('an untyped failure still reports its type', () async {
      final written = await failWith(StateError('wiring is wrong'));

      // The generic arm: the type usually names the layer that failed, which
      // is the difference between a fix and another dig.
      expect(written.join(), contains('StateError'));
    });

    test('the user is shown the locale key, not Arabic text', () async {
      final written = await failWith(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
        ),
      );

      // An English-locale user used to be shown a hardcoded Arabic string.
      expect(
        written,
        contains('THROWN:${LocaleKeys.errors_auth_failed_google}'),
      );
    });

    test('an untyped failure is reported to the user the same way', () async {
      final written = await failWith(StateError('wiring is wrong'));

      expect(
        written,
        contains('THROWN:${LocaleKeys.errors_auth_failed_google}'),
      );
    });

    test('an offline signal is NOT flattened into a Google failure', () async {
      when(() => google.authenticate()).thenThrow(OfflineException());

      // Deliberate pre-existing behaviour: connectivity must reach the
      // repository as OfflineFailure, not become "Google sign-in failed".
      await expectLater(
        datasource.loginWithGoogle(),
        throwsA(isA<OfflineException>()),
      );
    });
  });

  group('what the user is told', () {
    test('the message is a locale KEY, never a hardcoded string', () {
      // It used to throw literal Arabic, so an English-locale user was shown
      // Arabic. The key resolves per locale.
      expect(LocaleKeys.errors_auth_failed_google, 'errors.auth_failed_google');
    });

    test('the key is the same one the rest of this method already used', () {
      // The inconsistency being fixed: one arm of loginWithGoogle used the key
      // and two used a literal.
      expect(
        LocaleKeys.errors_auth_failed_google,
        isNot(contains('فشل')),
      );
    });
  });
}
