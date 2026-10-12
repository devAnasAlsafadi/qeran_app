import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/core/utils/widgets/qeran_snack_bar_widget.dart';
import 'package:qeran/features/profile/presentation/blocs/share_with_matchmaker/share_with_matchmaker_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/share_with_matchmaker/share_with_matchmaker_state.dart';
import 'package:qeran/features/profile/presentation/widgets/share_with_matchmaker_button.dart';

import '../../../../core/shipped_strings_rig.dart';

class _MockShare extends Mock implements ShareWithMatchmakerCubit {}

/// The shipped string at [section].[key] in [lang].
String _s(String lang, String section, String key) =>
    ((jsonDecode(File('assets/translations/$lang.json').readAsStringSync())
                as Map<String, dynamic>)[section]
            as Map<String, dynamic>)[key]
        as String;

const _waiting = ShareWithMatchmakerState(
  resolved: true,
  conversationId: null,
  isSharing: false,
  event: ShareEvent.none,
  eventVersion: 0,
);

/// The ask with no matchmaker to ask, never assigned or hers deleted, says
/// what the chat and the inquiry say: «جاري تعيين خطّابتك», calmly.
void main() {
  setUpAll(initShippedStrings);

  late _MockShare cubit;

  setUp(() {
    cubit = _MockShare();
    when(() => cubit.state).thenReturn(_waiting);
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.resolveMatchmaker()).thenAnswer((_) async {});
    when(() => cubit.close()).thenAnswer((_) async {});
    sl.registerFactory<ShareWithMatchmakerCubit>(() => cubit);
  });

  tearDown(() async {
    AppSnackBar.debugReset();
    await sl.reset();
  });

  Future<void> pump(WidgetTester tester, String lang) => pumpShippedStrings(
    tester,
    Locale(lang),
    builder: (_, child) => AppSnackBarHost(child: child!),
    child: const Center(child: ShareWithMatchmakerButton(userId: 'u-7')),
  );

  void expectWaitingToast(WidgetTester tester, String lang) {
    expect(
      find.text(_s(lang, 'chat', 'entry_no_matchmaker_title')),
      findsOneWidget,
    );
    expect(
      tester.widget<QeranSnackBarWidget>(find.byType(QeranSnackBarWidget)).type,
      SnackBarType.info,
    );
  }

  for (final lang in const ['ar', 'en']) {
    testWidgets('a tap with no matchmaker: «جاري تعيين خطّابتك» [$lang]', (
      tester,
    ) async {
      await pump(tester, lang);
      await tester.tap(
        find.text(_s(lang, 'profile', 'share_with_matchmaker_cta')),
      );
      await tester.pump();

      expectWaitingToast(tester, lang);
      verifyNever(() => cubit.share(any()));
      await tester.pump(const Duration(seconds: 5));
    });
  }

  testWidgets('the cubit\'s own no-matchmaker answer says the same', (
    tester,
  ) async {
    // Made inside the test: a controller from setUp runs outside fake async.
    final states = StreamController<ShareWithMatchmakerState>.broadcast();
    addTearDown(states.close);
    when(() => cubit.stream).thenAnswer((_) => states.stream);
    await pump(tester, 'ar');
    const answered = ShareWithMatchmakerState(
      resolved: true,
      conversationId: null,
      isSharing: false,
      event: ShareEvent.noMatchmaker,
      eventVersion: 1,
    );
    when(() => cubit.state).thenReturn(answered);
    states.add(answered);
    await tester.pump(); // the answer arrives
    await tester.pump(); // the toast draws

    expectWaitingToast(tester, 'ar');
    await tester.pump(const Duration(seconds: 5));
  });
}
