import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/features/auth/domain/entities/user_entity.dart';
import 'package:qeran/features/auth/presentation/blocs/login/login_state.dart';
import 'package:qeran/features/auth/presentation/blocs/register/register_state.dart';
import 'package:qeran/features/auth/presentation/blocs/whatsapp/whatsapp_state.dart';
import 'package:qeran/features/auth/presentation/screens/login_screen/login_screen.dart';
import 'package:qeran/features/auth/presentation/screens/register_screen/register_screen.dart';
import 'package:qeran/features/auth/presentation/screens/whatsapp_verification/whatsapp_verification.dart';

import '../../../core/shipped_fonts_rig.dart';
import '../../../core/shipped_strings_rig.dart';
import 'signed_in_rig.dart';

/// Where each sign-in sends each kind of account. Pinned before the three
/// screens' copies of this routing became one exit (run 7, item 3a), and
/// unchanged by it.
///
/// The role first: a matchmaker has none of a member's onboarding steps. A
/// member without a verified phone verifies it on top of the sign-in screen
/// (a push: its back returns there); everyone else replaces the screens.
final _kinds = <String, (UserEntity, String, bool)>{
  'a matchmaker': (account(role: 'Moderator'), RouteNames.matchmakerHome, true),
  'a member without a verified phone': (
    account(phone: false, answered: true),
    RouteNames.whatsappInput,
    false,
  ),
  'a member who has not answered the questions': (
    account(phone: true, answered: false),
    RouteNames.genderSelectionScreen,
    true,
  ),
  'a member with everything done': (
    account(phone: true, answered: true),
    RouteNames.homeScreen,
    true,
  ),
};

void main() {
  setUpAll(() async {
    await initShippedStrings();
    await loadShippedFonts();
  });

  for (final MapEntry(key: who, value: (user, route, cleared))
      in _kinds.entries) {
    testWidgets('login: $who goes to $route', (tester) async {
      final login = wireLogin();
      final exit = await pumpExit(tester, const LoginScreen());
      login.states.add(LoginSuccess(user));
      await settleExit(tester);
      expect(exit.route, route);
      expect(exit.cleared, cleared);
    });

    testWidgets('register, Google or Apple: $who goes to $route', (
      tester,
    ) async {
      wireRegister();
      final login = wireLogin();
      final exit = await pumpExit(tester, const RegisterScreen());
      login.states.add(LoginSuccess(user));
      await settleExit(tester);
      expect(exit.route, route);
      expect(exit.cleared, cleared);
    });
  }

  testWidgets('register by email goes on to the phone', (tester) async {
    final register = wireRegister();
    wireLogin();
    final exit = await pumpExit(tester, const RegisterScreen());
    register.add(RegisterSuccess(account()));
    await settleExit(tester);
    expect(exit.route, RouteNames.whatsappInput);
    expect(exit.cleared, isFalse);
  });

  // The code verifies the phone, whatever the answer's own flag says.
  for (final (answered, route) in [
    (true, RouteNames.homeScreen),
    (false, RouteNames.genderSelectionScreen),
  ]) {
    testWidgets('the WhatsApp code, answered: $answered, goes to $route', (
      tester,
    ) async {
      final whatsapp = wireWhatsapp();
      final exit = await pumpExit(tester, const WhatsappVerificationScreen());
      whatsapp.add(WhatsappOtpVerified(account(answered: answered)));
      await settleExit(tester);
      expect(exit.route, route);
      expect(exit.cleared, isTrue);
    });
  }
}
