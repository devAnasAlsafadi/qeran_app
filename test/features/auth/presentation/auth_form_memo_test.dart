import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/auth/presentation/auth_form_memo.dart';
import 'package:qeran/features/auth/presentation/screens/login_screen/login_controller.dart';
import 'package:qeran/features/auth/presentation/screens/register_screen/register_controller.dart';

/// Login and register each build their own controllers on every navigation, so
/// the fields are empty by construction when the member comes back. The memo
/// carries the identifying fields across that hop — and only those.
void main() {
  late AuthFormMemo memo;

  setUp(() => memo = AuthFormMemo());

  test('an email typed on register is waiting on login', () {
    final register = RegisterController(memo: memo);
    register.emailController.text = 'a@b.com';
    register.dispose();

    final login = LoginController(memo: memo);
    expect(login.emailController.text, 'a@b.com');
    login.dispose();
  });

  test('an email typed on login is waiting on register', () {
    // Login pushes register without disposing itself, so the value has to
    // reach the memo while the screen is still alive.
    final login = LoginController(memo: memo);
    login.emailController.text = 'c@d.com';

    final register = RegisterController(memo: memo);
    expect(register.emailController.text, 'c@d.com');
    register.dispose();
    login.dispose();
  });

  test('the username survives a trip to login and back', () {
    // The reported bug: register → login → register lost the name. Login has
    // no name field at all, so it can only survive in the memo.
    final first = RegisterController(memo: memo);
    first.nameController.text = 'سارة';
    first.emailController.text = 'a@b.com';
    first.dispose();

    final login = LoginController(memo: memo);
    login.dispose();

    final second = RegisterController(memo: memo);
    expect(second.nameController.text, 'سارة');
    expect(second.emailController.text, 'a@b.com');
    second.dispose();
  });

  test('the password never crosses the hop', () {
    final login = LoginController(memo: memo);
    login.emailController.text = 'a@b.com';
    login.passwordController.text = 'hunter2-secret';
    login.dispose();

    final register = RegisterController(memo: memo);
    expect(register.emailController.text, 'a@b.com');
    expect(register.passwordController.text, isEmpty);
    register.dispose();
  });

  test('the latest values win, and are trimmed', () {
    final register = RegisterController(memo: memo);
    register.emailController.text = 'first@x.com';
    register.emailController.text = '  second@x.com  ';
    register.nameController.text = '  دima  ';
    register.dispose();

    expect(memo.email, 'second@x.com');
    expect(memo.displayName, 'دima');
  });

  test('a successful sign-in clears both fields', () {
    final register = RegisterController(memo: memo);
    register.nameController.text = 'سارة';
    register.emailController.text = 'a@b.com';
    register.forgetForm();
    register.dispose();

    final next = RegisterController(memo: memo);
    expect(next.nameController.text, isEmpty);
    expect(next.emailController.text, isEmpty);
    next.dispose();
  });

  test('a disposed controller stops writing to the memo', () {
    // The listeners must come off, or a controller kept alive by a stale route
    // could overwrite what the live screen just typed.
    final register = RegisterController(memo: memo);
    register.emailController.text = 'live@x.com';
    register.nameController.text = 'live';
    final staleEmail = register.emailController;
    final staleName = register.nameController;
    register.dispose();

    expect(() => staleEmail.text = 'stale@x.com', throwsFlutterError);
    expect(() => staleName.text = 'stale', throwsFlutterError);
    expect(memo.email, 'live@x.com');
    expect(memo.displayName, 'live');
  });
}
