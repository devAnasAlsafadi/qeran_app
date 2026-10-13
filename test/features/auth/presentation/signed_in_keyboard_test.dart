import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/features/auth/domain/entities/user_entity.dart';
import 'package:qeran/features/auth/presentation/blocs/login/login_event.dart';
import 'package:qeran/features/auth/presentation/blocs/login/login_state.dart';
import 'package:qeran/features/auth/presentation/blocs/register/register_event.dart';
import 'package:qeran/features/auth/presentation/blocs/register/register_state.dart';
import 'package:qeran/features/auth/presentation/blocs/whatsapp/whatsapp_state.dart';
import 'package:qeran/features/auth/presentation/screens/login_screen/login_screen.dart';
import 'package:qeran/features/auth/presentation/screens/register_screen/register_screen.dart';
import 'package:qeran/features/auth/presentation/screens/register_screen/widgets/register_policy_checkbox.dart';
import 'package:qeran/features/auth/presentation/screens/whatsapp_verification/whatsapp_verification.dart';

import '../../../core/shipped_fonts_rig.dart';
import '../../../core/shipped_strings_rig.dart';
import 'signed_in_rig.dart';

/// Run 7, item 3a: on an iPhone the keyboard stayed up over home after a
/// Google sign-in. A field left focused under Google's sheet got the keyboard
/// back when the sheet closed, and the screens were then replaced under it.
/// So: nothing is focused when a sign-in starts, and the keyboard is told to
/// close before any sign-in leaves for the next screen — both roles.
void main() {
  setUpAll(() async {
    await initShippedStrings();
    await loadShippedFonts();
    registerFallbackValue(LoginWithGoogleRequested());
    registerFallbackValue(
      RegisterRequested(name: 'n', email: 'e', password: 'p'),
    );
  });

  final exits = <String, UserEntity>{
    'a member': account(phone: true, answered: true),
    'a matchmaker': account(role: 'Moderator'),
    'a member sent to verify the phone': account(phone: false),
    'a member sent to the questions': account(phone: true, answered: false),
  };

  /// The exit happened with the keyboard told to close before it.
  void expectClosedFirst(WidgetTester tester, Exit exit) {
    expect(exit.route, isNotNull);
    expect(exit.hideAt, greaterThan(0));
    expect(tester.testTextInput.isVisible, isFalse);
  }

  for (final MapEntry(key: who, value: user) in exits.entries) {
    testWidgets('login: the keyboard closes before $who leaves', (
      tester,
    ) async {
      final login = wireLogin();
      final exit = await pumpExit(tester, const LoginScreen());
      await tester.showKeyboard(find.byType(TextField).first);
      login.states.add(LoginSuccess(user));
      await settleExit(tester);
      expectClosedFirst(tester, exit);
    });

    testWidgets('register, Google: the keyboard closes before $who leaves', (
      tester,
    ) async {
      wireRegister();
      final login = wireLogin();
      final exit = await pumpExit(tester, const RegisterScreen());
      await tester.showKeyboard(find.byType(TextField).first);
      login.states.add(LoginSuccess(user));
      await settleExit(tester);
      expectClosedFirst(tester, exit);
    });
  }

  testWidgets('the WhatsApp code: the keyboard closes before home', (
    tester,
  ) async {
    final whatsapp = wireWhatsapp();
    final exit = await pumpExit(tester, const WhatsappVerificationScreen());
    await tester.showKeyboard(find.byType(TextField).last);
    whatsapp.add(WhatsappOtpVerified(account(answered: true)));
    await settleExit(tester);
    expectClosedFirst(tester, exit);
  });

  /// Pumps [screen], focuses a field, and returns how many keyboard-hide calls
  /// had gone out when the bloc was asked to sign in (-1: never asked).
  Future<int Function()> focusedSignIn(
    WidgetTester tester,
    Widget screen,
  ) async {
    final login = wireLogin();
    var hidesAtSignIn = -1;
    when(() => login.bloc.add(any())).thenAnswer((_) {
      hidesAtSignIn = keyboardHides(tester);
    });
    await pumpExit(tester, screen);
    await tester.showKeyboard(find.byType(TextField).first);
    return () => hidesAtSignIn;
  }

  for (final (where, screen) in [
    ('login', const LoginScreen()),
    ('register', const RegisterScreen()),
  ]) {
    testWidgets(
      '$where: the Google tile closes the keyboard before the sheet',
      (tester) async {
        if (screen is RegisterScreen) wireRegister();
        final hidesAtSignIn = await focusedSignIn(tester, screen);
        await tester.tap(find.byType(SvgPicture));
        await tester.pump();
        expect(hidesAtSignIn(), greaterThan(0));
        expect(tester.testTextInput.isVisible, isFalse);
      },
    );
  }

  testWidgets('login by email: the keyboard closes before signing in', (
    tester,
  ) async {
    final hidesAtSignIn = await focusedSignIn(tester, const LoginScreen());
    await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextField).at(1), 'Abcdefg1!');
    await tester.tap(find.byType(QeranButton).first);
    await tester.pump();
    expect(hidesAtSignIn(), greaterThan(0));
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('register by email: the keyboard closes before signing up', (
    tester,
  ) async {
    final bloc = MockRegisterBloc();
    var hidesAtSignUp = -1;
    when(() => bloc.add(any())).thenAnswer((_) {
      hidesAtSignUp = keyboardHides(tester);
    });
    wireRegister(bloc);
    wireLogin();
    await pumpExit(tester, const RegisterScreen());
    await tester.enterText(find.byType(TextField).at(0), 'Huda');
    await tester.enterText(find.byType(TextField).at(1), 'a@b.com');
    await tester.enterText(find.byType(TextField).at(2), 'Abcdefg1!');
    tester
            .widget<RegisterPolicyCheckbox>(find.byType(RegisterPolicyCheckbox))
            .acceptedPolicyNotifier
            .value =
        true;
    await tester.tap(find.byType(QeranButton).first);
    await tester.pump();
    expect(hidesAtSignUp, greaterThan(0));
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('register by email: the keyboard closes before the phone step', (
    tester,
  ) async {
    final register = wireRegister();
    wireLogin();
    final exit = await pumpExit(tester, const RegisterScreen());
    await tester.showKeyboard(find.byType(TextField).first);
    register.add(RegisterSuccess(account()));
    await settleExit(tester);
    expectClosedFirst(tester, exit);
  });
}
