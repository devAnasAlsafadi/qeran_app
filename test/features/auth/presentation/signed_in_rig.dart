import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/theme/qeran_theme.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/auth/domain/entities/user_entity.dart';
import 'package:qeran/features/auth/presentation/blocs/login/login_bloc.dart';
import 'package:qeran/features/auth/presentation/blocs/login/login_state.dart';
import 'package:qeran/features/auth/presentation/blocs/register/register_bloc.dart';
import 'package:qeran/features/auth/presentation/blocs/register/register_state.dart';
import 'package:qeran/features/auth/presentation/blocs/whatsapp/whatsapp_bloc.dart';
import 'package:qeran/features/auth/presentation/blocs/whatsapp/whatsapp_state.dart';

import '../../../core/shipped_strings_rig.dart';

/// For the sign-in exits (run 7, item 3a): the real screens over blocs whose
/// states a test pushes, every named route answered and recorded, and the
/// keyboard's hide call placed against the navigation.

class MockLoginBloc extends Mock implements LoginBloc {}

class MockRegisterBloc extends Mock implements RegisterBloc {}

class MockWhatsappBloc extends Mock implements WhatsappBloc {}

/// Registers [bloc] in `sl` until the test ends, and closes [states].
void _own<B extends Object>(B bloc, StreamController<Object> states) {
  sl.registerFactory<B>(() => bloc);
  addTearDown(() {
    states.close();
    sl.unregister<B>();
  });
}

/// A login bloc whose states the test adds to the returned controller.
({MockLoginBloc bloc, StreamController<LoginState> states}) wireLogin() {
  final bloc = MockLoginBloc();
  final states = StreamController<LoginState>.broadcast();
  when(() => bloc.state).thenReturn(LoginInitial());
  when(() => bloc.stream).thenAnswer((_) => states.stream);
  when(bloc.close).thenAnswer((_) async {});
  _own<LoginBloc>(bloc, states);
  return (bloc: bloc, states: states);
}

/// [bloc] for a test that stubs its `add`; a fresh mock otherwise.
StreamController<RegisterState> wireRegister([MockRegisterBloc? given]) {
  final bloc = given ?? MockRegisterBloc();
  final states = StreamController<RegisterState>.broadcast();
  when(() => bloc.state).thenReturn(RegisterInitial());
  when(() => bloc.stream).thenAnswer((_) => states.stream);
  when(bloc.close).thenAnswer((_) async {});
  _own<RegisterBloc>(bloc, states);
  return states;
}

StreamController<WhatsappState> wireWhatsapp() {
  final bloc = MockWhatsappBloc();
  final states = StreamController<WhatsappState>.broadcast();
  when(() => bloc.state).thenReturn(WhatsappInitial());
  when(() => bloc.stream).thenAnswer((_) => states.stream);
  when(bloc.close).thenAnswer((_) async {});
  _own<WhatsappBloc>(bloc, states);
  return states;
}

UserEntity account({String? role, bool? phone, bool? answered}) => UserEntity(
  id: '1',
  name: 'n',
  email: 'e@x.com',
  token: 't',
  role: role,
  isPhoneVerified: phone,
  hasAnsweredQuestions: answered,
);

/// Where an account went: the route's name, and whether the screens under it
/// were cleared (`pushNamedAndRemoveUntil`) or kept (a plain push). [hideAt]
/// is how many keyboard-hide calls had gone out when the route was pushed.
class Exit {
  String? route;
  bool cleared = false;
  int hideAt = -1;
}

class _Recorder extends NavigatorObserver {
  _Recorder(this.exit, this.hides);
  final Exit exit;
  final int Function() hides;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previous) {
    final name = route.settings.name;
    if (name == null || name == '/') return;
    exit
      ..route = name
      ..hideAt = hides();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previous) =>
      exit.cleared = true;
}

int keyboardHides(WidgetTester tester) => tester.testTextInput.log
    .where((call) => call.method == 'TextInput.hide')
    .length;

/// Pumps [screen] as the home route, every named route answered.
Future<Exit> pumpExit(WidgetTester tester, Widget screen) async {
  final exit = Exit();
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await pumpShippedStrings(
    tester,
    const Locale('ar'),
    child: screen,
    settle: false,
    // The app's theme picks the shipped face by locale; without it the text
    // measures in the test font, and the OTP screen's resend row overflows.
    builder: (_, navigator) =>
        Theme(data: QeranTheme.light(const Locale('ar')), child: navigator!),
    navigatorObservers: [_Recorder(exit, () => keyboardHides(tester))],
    onGenerateRoute: (settings) => MaterialPageRoute(
      settings: settings,
      builder: (_) => Text('route ${settings.name}'),
    ),
  );
  return exit;
}

/// Lets a pushed state reach its listener and the navigation run.
Future<void> settleExit(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  // Past the success snackbar's hold, so no timer outlives the test.
  await tester.pump(const Duration(seconds: 5));
}
