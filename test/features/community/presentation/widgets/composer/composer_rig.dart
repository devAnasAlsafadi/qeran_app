import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_composer.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/community/presentation/blocs/composer/community_composer_cubit.dart';
import 'package:qeran/features/community/presentation/widgets/composer/community_composer.dart';

import '../../../../../core/shipped_strings_rig.dart';
import '../../blocs/composer/composer_cubit_harness.dart';

/// The composer at the foot of a phone, in [locale]'s UI.
Future<void> pumpComposer(
  WidgetTester tester,
  ComposerHarness h, {
  Locale locale = const Locale('en'),
  bool readOnly = false,
}) async {
  addTearDown(AppSnackBar.debugReset);
  await h.cubit.loadConfig();
  await pumpShippedStrings(
    tester,
    locale,
    child: AppSnackBarHost(
      child: BlocProvider<CommunityComposerCubit>.value(
        value: h.cubit,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: CommunityComposer(readOnly: readOnly),
        ),
      ),
    ),
  );
}

Finder get composerField => find.byType(TextField);

String composerText(WidgetTester tester) =>
    tester.widget<TextField>(composerField).controller!.text;

bool canSend(WidgetTester tester) =>
    tester.widget<QeranSendButton>(find.byType(QeranSendButton)).enabled;

Future<void> typeIn(WidgetTester tester, String text) async {
  await tester.enterText(composerField, text);
  await tester.pump();
}

Future<void> sendIt(WidgetTester tester) async {
  await tester.tap(find.byType(QeranSendButton));
  await tester.pump();
  await tester.pump();
}
