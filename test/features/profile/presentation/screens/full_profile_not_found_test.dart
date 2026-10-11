import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/block/presentation/blocs/block_action_cubit.dart';
import 'package:qeran/features/profile/domain/entities/profile_entry_source.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_details/profile_details_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_details/profile_details_state.dart';
import 'package:qeran/features/profile/presentation/full_profile_details_args.dart';
import 'package:qeran/features/profile/presentation/screens/full_profile_details_screen.dart';

import '../../../../core/shipped_strings_rig.dart';

class _MockDetails extends Mock implements ProfileDetailsCubit {}

class _MockSession extends Mock implements UserSessionCubit {}

/// The shipped `profile.not_available` in [lang].
String _notAvailable(String lang) =>
    ((jsonDecode(File('assets/translations/$lang.json').readAsStringSync())
                as Map<String, dynamic>)['profile']
            as Map<String, dynamic>)['not_available']
        as String;

/// PROFILE_NOT_FOUND (missing or hidden): the screen says so once, as its
/// full-screen state, with no snackbar repeating it, and stays open.
void main() {
  setUpAll(initShippedStrings);

  late _MockDetails details;
  late StreamController<ProfileDetailsState> states;

  setUp(() {
    AppSnackBar.debugReset();
    details = _MockDetails();
    states = StreamController<ProfileDetailsState>.broadcast();
    when(() => details.state).thenReturn(const ProfileDetailsLoading());
    when(() => details.stream).thenAnswer((_) => states.stream);
    when(
      () => details.init(
        userId: any(named: 'userId'),
        seed: any(named: 'seed'),
      ),
    ).thenAnswer((_) async {});
    when(() => details.close()).thenAnswer((_) async {});
    final session = _MockSession();
    when(() => session.currentUser).thenReturn(null);
    sl.registerFactory<ProfileDetailsCubit>(() => details);
    sl.registerSingleton<UserSessionCubit>(session);
    // The ⋮ beside it; never tapped here.
    sl.registerFactoryParam<BlockActionCubit, BlockOrigin, void>(
      (_, _) => BlockActionCubit(block: (_) => throw StateError('not here')),
    );
  });

  tearDown(() async {
    AppSnackBar.debugReset();
    await states.close();
    await sl.reset();
  });

  for (final lang in const ['ar', 'en']) {
    testWidgets('not found: said once, by the screen [$lang]', (tester) async {
      await pumpShippedStrings(
        tester,
        Locale(lang),
        settle: false,
        builder: (_, child) => AppSnackBarHost(child: child!),
        child: const FullProfileDetailsScreen(
          args: FullProfileDetailsArgs(
            userId: 'u-1',
            entry: ProfileEntrySource.discovery,
          ),
        ),
      );

      when(() => details.state).thenReturn(const ProfileDetailsNotFound());
      states.add(const ProfileDetailsNotFound());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(_notAvailable(lang)), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });
  }
}
