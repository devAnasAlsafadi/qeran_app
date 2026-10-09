import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/profile/presentation/blocs/delete_account/delete_account_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/delete_account/delete_account_state.dart';
import 'package:qeran/features/profile/presentation/widgets/delete_account_sheet.dart';

import '../../../../core/shipped_strings_rig.dart';

class _MockDelete extends Mock implements DeleteAccountCubit {}

/// The shipped `settings.<key>` in [lang].
String _s(String lang, String key) =>
    ((jsonDecode(File('assets/translations/$lang.json').readAsStringSync())
                as Map<String, dynamic>)['settings']
            as Map<String, dynamic>)[key]
        as String;

/// Apple and Google ask apps that sell subscriptions to say that deleting the
/// account doesn't cancel the store subscription. The member's delete sheet
/// says it to everyone: the server may not know of a purchase yet.
void main() {
  setUpAll(initShippedStrings);

  setUp(() {
    final cubit = _MockDelete();
    when(() => cubit.state).thenReturn(const DeleteAccountState());
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.close()).thenAnswer((_) async {});
    sl.registerFactory<DeleteAccountCubit>(() => cubit);
  });

  tearDown(sl.reset);

  final expiresAt = DateTime(2026, 12, 31);

  Future<void> open(
    WidgetTester tester,
    String lang, {
    required bool active,
  }) async {
    final context = await pumpShippedStrings(tester, Locale(lang));
    showDeleteAccountSheet(
      context,
      subscriptionActive: active,
      expiresAt: active ? expiresAt : null,
    );
    await tester.pumpAndSettle();
  }

  for (final lang in const ['ar', 'en']) {
    final store = find.text(_s(lang, 'delete_account_consequence_store'));

    testWidgets('no subscription: still says the store keeps it [$lang]', (
      tester,
    ) async {
      await open(tester, lang, active: false);

      expect(store, findsOneWidget);
    });

    testWidgets('an active subscription: its end date, and the store line '
        '[$lang]', (tester) async {
      await open(tester, lang, active: true);

      final date = DateFormat.yMMMMd(lang).format(expiresAt);
      final forfeit = _s(
        lang,
        'delete_account_consequence_subscription',
      ).replaceFirst('{date}', date);
      expect(find.text(forfeit), findsOneWidget);
      expect(store, findsOneWidget);
    });
  }

  test('the forfeit line never says deleting cancels the subscription', () {
    expect(
      _s('ar', 'delete_account_consequence_subscription'),
      isNot(contains('يُلغي')),
    );
    expect(
      _s('en', 'delete_account_consequence_subscription').toLowerCase(),
      isNot(contains('cancel')),
    );
  });
}
