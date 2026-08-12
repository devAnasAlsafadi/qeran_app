import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/auth/presentation/auth_email_memo.dart';
import 'package:qeran/features/auth/presentation/screens/login_screen/login_controller.dart';
import 'package:qeran/features/auth/presentation/screens/register_screen/register_controller.dart';

/// Login and register each build their own controllers on every navigation, so
/// the fields are empty by construction when the member comes back. The memo
/// carries the email across that hop — and only the email.
void main() {
  late AuthEmailMemo memo;

  setUp(() => memo = AuthEmailMemo());

  test('an email typed on register is waiting on login', () {
    final register = RegisterController(emailMemo: memo);
    register.emailController.text = 'a@b.com';
    register.dispose();

    final login = LoginController(emailMemo: memo);
    expect(login.emailController.text, 'a@b.com');
    login.dispose();
  });

  test('an email typed on login is waiting on register', () {
    // Login pushes register without disposing itself, so the value has to
    // reach the memo while the screen is still alive.
    final login = LoginController(emailMemo: memo);
    login.emailController.text = 'c@d.com';

    final register = RegisterController(emailMemo: memo);
    expect(register.emailController.text, 'c@d.com');
    register.dispose();
    login.dispose();
  });

  test('the password never crosses the hop', () {
    final login = LoginController(emailMemo: memo);
    login.emailController.text = 'a@b.com';
    login.passwordController.text = 'hunter2-secret';
    login.dispose();

    final register = RegisterController(emailMemo: memo);
    expect(register.emailController.text, 'a@b.com');
    expect(register.passwordController.text, isEmpty);
    register.dispose();
  });

  test('the name is register-only and does not leak anywhere', () {
    final register = RegisterController(emailMemo: memo);
    register.nameController.text = 'سارة';
    register.dispose();

    final second = RegisterController(emailMemo: memo);
    expect(second.nameController.text, isEmpty);
    second.dispose();
  });

  test('the latest value wins, and is trimmed', () {
    final login = LoginController(emailMemo: memo);
    login.emailController.text = 'first@x.com';
    login.emailController.text = '  second@x.com  ';
    login.dispose();

    expect(memo.email, 'second@x.com');
  });

  test('a successful sign-in clears the memo', () {
    final login = LoginController(emailMemo: memo);
    login.emailController.text = 'a@b.com';
    login.forgetEmail();
    login.dispose();

    final next = LoginController(emailMemo: memo);
    expect(next.emailController.text, isEmpty);
    next.dispose();
  });

  test('a disposed controller stops writing to the memo', () {
    // The listener must come off, or a controller kept alive by a stale route
    // could overwrite what the live screen just typed.
    final login = LoginController(emailMemo: memo);
    login.emailController.text = 'live@x.com';
    final stale = login.emailController;
    login.dispose();

    expect(() => stale.text = 'stale@x.com', throwsFlutterError);
    expect(memo.email, 'live@x.com');
  });
}
