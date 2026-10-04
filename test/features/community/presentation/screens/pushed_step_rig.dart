import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/connectivity/connectivity_cubit.dart';
import 'package:qeran/core/utils/app_snackbar.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../fixtures/community_mock_harness.dart';

/// Opens a pushed step — the name step, the guidelines — the way the
/// composer will: from a screen with one button, «open», that runs [open].
/// Under what the app's root holds (the toasts, the connection), in
/// [locale] on a phone [size].
Future<void> openPushedStep(
  WidgetTester tester,
  Future<void> Function(BuildContext context) open, {
  Locale locale = const Locale('en'),
  Size size = const Size(390, 900),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  addTearDown(AppSnackBar.debugReset);
  await pumpShippedStrings(
    tester,
    locale,
    builder: (_, navigator) => BlocProvider<ConnectivityCubit>(
      create: (_) => ConnectivityCubit(service: FakeConnectivity()),
      child: AppSnackBarHost(child: navigator!),
    ),
    child: Builder(
      builder: (context) =>
          TextButton(onPressed: () => open(context), child: const Text('open')),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
