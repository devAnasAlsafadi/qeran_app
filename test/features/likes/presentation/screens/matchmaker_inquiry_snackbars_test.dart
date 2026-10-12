import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/core/utils/widgets/qeran_snack_bar_widget.dart';
import 'package:qeran/features/likes/presentation/blocs/matchmaker_inquiry_state.dart';
import 'package:qeran/features/likes/presentation/screens/matchmaker_inquiry_snackbars.dart';

import '../../../../core/shipped_strings_rig.dart';

/// The shipped string at [section].[key] in [lang].
String _s(String lang, String section, String key) =>
    ((jsonDecode(File('assets/translations/$lang.json').readAsStringSync())
                as Map<String, dynamic>)[section]
            as Map<String, dynamic>)[key]
        as String;

/// An inquiry with no one to ask says what the chat says to a member waiting
/// for her matchmaker, calmly; a real failure stays an error.
void main() {
  setUpAll(initShippedStrings);
  tearDown(AppSnackBar.debugReset);

  Future<void> show(
    WidgetTester tester,
    String lang,
    InquiryEvent event,
  ) async {
    final context = await pumpShippedStrings(
      tester,
      Locale(lang),
      builder: (_, child) => AppSnackBarHost(child: child!),
    );
    onInquiryEvent(context, MatchmakerInquiryState(event: event));
    await tester.pump();
  }

  SnackBarType shownType(WidgetTester tester) =>
      tester.widget<QeranSnackBarWidget>(find.byType(QeranSnackBarWidget)).type;

  for (final lang in const ['ar', 'en']) {
    testWidgets('no matchmaker: «جاري تعيين خطّابتك», as info [$lang]', (
      tester,
    ) async {
      await show(tester, lang, InquiryEvent.noMatchmaker);

      expect(
        find.text(_s(lang, 'chat', 'entry_no_matchmaker_title')),
        findsOneWidget,
      );
      expect(shownType(tester), SnackBarType.info);
      await tester.pump(const Duration(seconds: 5));
    });
  }

  testWidgets('a failure is still the error', (tester) async {
    await show(tester, 'ar', InquiryEvent.failure);

    expect(
      find.text(_s('ar', 'likes', 'matches_action_request_failed')),
      findsOneWidget,
    );
    expect(shownType(tester), SnackBarType.error);
    await tester.pump(const Duration(seconds: 5));
  });
}
