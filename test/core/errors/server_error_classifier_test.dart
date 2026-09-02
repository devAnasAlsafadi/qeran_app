import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/errors/server_error_classifier.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// `serverFailureKey` is the one place a backend failure becomes something the
/// UI may translate. Each test below kills a different mutation of it: drop the
/// map lookup, drop the fallback, drop the transport branch, or return the
/// server's message. Any of those would put English prose into an Arabic UI.
void main() {
  const codeKeys = {
    'INVALID_CREDENTIALS': LocaleKeys.errors_invalid_credentials,
    'ACCOUNT_DEACTIVATED': LocaleKeys.errors_account_deactivated,
  };

  String keyFor(ServerException e) =>
      serverFailureKey(e, codeKeys: codeKeys, label: 'TEST', tag: 'TEST');

  test('a known errorCode resolves to its specific key', () {
    final key = keyFor(
      CodedServerException(
        message: 'Invalid email or password',
        errorCode: 'INVALID_CREDENTIALS',
      ),
    );
    expect(key, LocaleKeys.errors_invalid_credentials);
    // Not merely "some key" — a blanket-generic mutant must fail here.
    expect(key, isNot(LocaleKeys.errors_generic));
  });

  test('an unknown errorCode degrades to errors.generic', () {
    expect(
      keyFor(
        CodedServerException(
          message: 'Some future server condition',
          errorCode: 'SOME_FUTURE_CODE',
        ),
      ),
      LocaleKeys.errors_generic,
    );
  });

  test('a null errorCode degrades to errors.generic', () {
    expect(
      keyFor(CodedServerException(message: 'No code at all', errorCode: null)),
      LocaleKeys.errors_generic,
    );
  });

  test('the raw English server message never escapes', () {
    // The lead regression: this string used to reach `.t()` and render as-is.
    const prose = 'An account with this email already exists';
    final key = keyFor(ServerException(message: prose));
    expect(key, isNot(contains('already exists')));
    expect(key, LocaleKeys.errors_generic);
  });

  test('an Arabic server sentence never escapes either', () {
    // Prose is prose in both directions — an English UI must not receive this.
    expect(
      keyFor(ServerException(message: 'البريد الإلكتروني مستخدم بالفعل')),
      LocaleKeys.errors_generic,
    );
  });

  test('transport keys survive — a timeout stays errors.timeout', () {
    // `HttpConsumer` already emits locale keys for transport failures. Blanket
    // "generic" would downgrade a precise message the user benefits from.
    expect(
      keyFor(ServerException(message: LocaleKeys.errors_timeout)),
      LocaleKeys.errors_timeout,
    );
  });
}
