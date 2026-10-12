import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/matchmaker/account/presentation/blocs/matchmaker_delete_account_cubit.dart';
import 'package:qeran/features/matchmaker/account/presentation/widgets/matchmaker_delete_account_sheet.dart';
import 'package:qeran/features/profile/presentation/blocs/delete_account/delete_account_state.dart';

import '../../../core/shipped_strings_rig.dart';

class _MockDelete extends Mock implements MatchmakerDeleteAccountCubit {}

/// The shipped `settings.<key>` in [lang].
String _s(String lang, String key) =>
    ((jsonDecode(File('assets/translations/$lang.json').readAsStringSync())
                as Map<String, dynamic>)['settings']
            as Map<String, dynamic>)[key]
        as String;

/// Her delete sheet says what Tariq's deploy removes of hers — her Community
/// posts with their media and comments, her comments, replies and likes, and
/// her chats from the members' side — in one line of her own. Never the
/// member's line, which speaks of interests she never shows.
void main() {
  setUpAll(initShippedStrings);

  setUp(() {
    final cubit = _MockDelete();
    when(() => cubit.state).thenReturn(const DeleteAccountState());
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.close()).thenAnswer((_) async {});
    sl.registerFactory<MatchmakerDeleteAccountCubit>(() => cubit);
  });

  tearDown(sl.reset);

  for (final lang in const ['ar', 'en']) {
    testWidgets('her own line, not the member\'s [$lang]', (tester) async {
      final context = await pumpShippedStrings(tester, Locale(lang));

      showMatchmakerDeleteAccountSheet(context);
      await tester.pumpAndSettle();

      expect(
        find.text(_s(lang, 'delete_account_consequence_matchmaker')),
        findsOneWidget,
      );
      expect(
        find.text(_s(lang, 'delete_account_consequence_data')),
        findsNothing,
      );
    });
  }
}
