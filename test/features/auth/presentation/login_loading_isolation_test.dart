import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/auth/presentation/blocs/login/login_state.dart';

/// The three sign-in paths share one bloc. Before this, a single
/// `LoginLoading` meant tapping "login" also spun the Google button.
void main() {
  bool emailSpins(LoginState s) =>
      s is LoginLoading && s.method == AuthMethod.email;
  bool googleSpins(LoginState s) =>
      s is LoginLoading && s.method == AuthMethod.google;
  bool appleSpins(LoginState s) =>
      s is LoginLoading && s.method == AuthMethod.apple;
  bool anyBusy(LoginState s) => s is LoginLoading;

  test('email sign-in spins only the login button', () {
    final state = LoginLoading(AuthMethod.email);
    expect(emailSpins(state), isTrue);
    expect(googleSpins(state), isFalse);
    expect(appleSpins(state), isFalse);
  });

  test('google sign-in spins only the google button', () {
    final state = LoginLoading(AuthMethod.google);
    expect(googleSpins(state), isTrue);
    expect(emailSpins(state), isFalse);
    expect(appleSpins(state), isFalse);
  });

  test('apple sign-in spins only the apple button', () {
    final state = LoginLoading(AuthMethod.apple);
    expect(appleSpins(state), isTrue);
    expect(emailSpins(state), isFalse);
    expect(googleSpins(state), isFalse);
  });

  test('every loading method still marks the screen busy', () {
    // Buttons that are not spinning must still refuse taps, or a user could
    // fire a second sign-in while the first is in flight.
    for (final method in AuthMethod.values) {
      expect(anyBusy(LoginLoading(method)), isTrue);
    }
  });

  test('non-loading states spin nothing and are not busy', () {
    for (final state in <LoginState>[
      LoginInitial(),
      LoginFailure('boom'),
    ]) {
      expect(anyBusy(state), isFalse);
      expect(emailSpins(state), isFalse);
      expect(googleSpins(state), isFalse);
      expect(appleSpins(state), isFalse);
    }
  });
}
