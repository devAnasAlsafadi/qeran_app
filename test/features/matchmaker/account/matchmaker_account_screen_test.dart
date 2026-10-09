import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/auth/domain/entities/user_entity.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';
import 'package:qeran/features/matchmaker/account/presentation/blocs/matchmaker_account_cubit.dart';
import 'package:qeran/features/matchmaker/account/presentation/blocs/matchmaker_account_state.dart';
import 'package:qeran/features/matchmaker/account/presentation/screens/matchmaker_account_screen.dart';
import 'package:qeran/features/settings/presentation/widgets/settings_logout_card.dart';

import '../../../core/shipped_strings_rig.dart';
import 'matchmaker_me_fixtures.dart';

class _MockAccount extends Mock implements MatchmakerAccountCubit {}

class _MockSession extends Mock implements UserSessionCubit {}

/// Her Account screen as it stands before E1 splits its long functions: what
/// each outcome shows and where each row leads (characterization).
String _en(String path) {
  Object? node = jsonDecode(
    File('assets/translations/en.json').readAsStringSync(),
  );
  for (final part in path.split('.')) {
    node = (node! as Map<String, dynamic>)[part];
  }
  return node! as String;
}

void main() {
  setUpAll(initShippedStrings);

  late _MockAccount account;
  late _MockSession session;
  late StreamController<MatchmakerAccountState> states;
  late MatchmakerAccountState current;

  setUp(() {
    account = _MockAccount();
    session = _MockSession();
    states = StreamController.broadcast();
    current = MatchmakerAccountState(
      status: MatchmakerAccountStatus.loaded,
      me: meWith(),
    );
    when(() => account.state).thenAnswer((_) => current);
    when(() => account.stream).thenAnswer((_) => states.stream);
    when(() => account.load()).thenAnswer((_) async {});
    when(() => account.close()).thenAnswer((_) async {});
    when(() => account.deactivate()).thenAnswer((_) async {});
    when(() => session.state).thenReturn(
      const UserSessionAuthenticated(
        UserEntity(id: 'mm-1', name: 'هدى', email: 'a@b.c', role: 'Moderator'),
      ),
    );
    when(() => session.stream).thenAnswer((_) => const Stream.empty());
    when(() => session.signOut()).thenAnswer((_) async {});
    sl.registerFactory<MatchmakerAccountCubit>(() => account);
  });

  tearDown(() async {
    await states.close();
    await sl.reset();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpShippedStrings(
      tester,
      const Locale('en'),
      child: BlocProvider<UserSessionCubit>.value(
        value: session,
        child: const MatchmakerAccountScreen(),
      ),
      builder: (context, child) => AppSnackBarHost(child: child!),
      onGenerateRoute: (s) => MaterialPageRoute<void>(
        settings: s,
        builder: (_) => Text('route ${s.name}'),
      ),
    );
  }

  /// Emits [next] as a new event, and lets its toast finish.
  Future<void> emit(WidgetTester tester, MatchmakerAccountState next) async {
    current = next.copyWith(eventVersion: current.eventVersion + 1);
    states.add(current);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> drain(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 5));

  testWidgets('a photo saved: its success toast', (tester) async {
    await pump(tester);
    await emit(
      tester,
      current.copyWith(outcome: MatchmakerAccountOutcome.uploadPhotoSuccess),
    );
    expect(find.text(_en('matchmaker.account_photo_updated')), findsOneWidget);
    await drain(tester);
  });

  testWidgets('a failure toasts its key; an inline one does not', (
    tester,
  ) async {
    await pump(tester);
    await emit(
      tester,
      current.copyWith(
        outcome: MatchmakerAccountOutcome.failure,
        errorKind: MatchmakerAccountErrorKind.validation,
        actionErrorKey: 'errors.bad_request',
      ),
    );
    expect(find.text(_en('errors.bad_request')), findsNothing);

    await emit(
      tester,
      current.copyWith(
        outcome: MatchmakerAccountOutcome.failure,
        errorKind: MatchmakerAccountErrorKind.generic,
        actionErrorKey: 'errors.timeout',
      ),
    );
    expect(find.text(_en('errors.timeout')), findsOneWidget);
    await drain(tester);
  });

  testWidgets('deactivated: signed out, on login, with its toast', (
    tester,
  ) async {
    await pump(tester);
    await emit(
      tester,
      current.copyWith(outcome: MatchmakerAccountOutcome.deactivateSuccess),
    );
    await tester.pumpAndSettle();

    verify(() => session.signOut()).called(1);
    expect(find.text('route ${RouteNames.loginScreen}'), findsOneWidget);
    expect(
      find.text(_en('matchmaker.account_deactivate_success')),
      findsOneWidget,
    );
    await drain(tester);
  });

  testWidgets('logout, confirmed: signed out, on login, with its toast', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byType(SettingsLogoutCard));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en('common.logout')).last);
    await tester.pumpAndSettle();

    verify(() => session.signOut()).called(1);
    expect(find.text('route ${RouteNames.loginScreen}'), findsOneWidget);
    expect(find.text(_en('common.logout_success')), findsOneWidget);
    await drain(tester);
  });

  for (final (row, route) in [
    ('settings.notifications_row', RouteNames.matchmakerNotifications),
    ('settings.support_row', RouteNames.settingsSupport),
    ('matchmaker.affiliate_row_title', RouteNames.matchmakerAffiliate),
    ('settings.terms_row', RouteNames.settingsTerms),
  ]) {
    testWidgets('$row opens $route', (tester) async {
      await pump(tester);
      await tester.tap(find.text(_en(row)));
      await tester.pumpAndSettle();
      expect(find.text('route $route'), findsOneWidget);
    });
  }

  testWidgets('before /me loads, the header names her from the session', (
    tester,
  ) async {
    current = const MatchmakerAccountState(
      status: MatchmakerAccountStatus.loading,
    );
    await pump(tester);
    expect(find.text('هدى'), findsWidgets);
  });
}
