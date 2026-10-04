import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/features/community/domain/entities/comment_submit_outcome.dart';
import 'package:qeran/features/community/domain/entities/guidelines_acceptance.dart';
import 'package:qeran/features/community/presentation/blocs/composer/community_gate.dart';
import 'package:qeran/features/community/presentation/widgets/guidelines/guidelines_text.dart';
import 'package:qeran/features/community/presentation/widgets/name_gate/name_gate_form.dart';

import '../../../../../core/shipped_strings_rig.dart';
import '../../blocs/composer/composer_cubit_harness.dart';
import '../../screens/guidelines_rig.dart';
import '../../screens/name_gate_rig.dart';
import 'composer_rig.dart';

/// The steps over the composer, end to end (F1–F7, S5): the real name step
/// and guidelines pages, pushed from the post screen's composer.

FocusNode _focusOf(WidgetTester tester) =>
    tester.widget<TextField>(composerField).focusNode!;

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(QeranButton, label));
  await tester.pumpAndSettle();
}

/// A member who owes both steps, at the composer: their name is still the
/// placeholder and the guidelines unaccepted, as the app's gate has it.
Future<ComposerHarness> _ownsBothSteps(WidgetTester tester) async {
  final names = NameGateHarness(profile: gateProfile(accepted: false));
  addTearDown(names.dispose);
  final rules = GuidelinesHarness(
    onAccepted: names.gate.markCommunityGuidelinesAccepted,
  );
  await names.gate.refresh();
  names.answerSaves([Right(gateProfile(name: 'Dima'))]);
  rules.accepts([const Right(GuidelinesAcceptance.accepted)]);
  final h = ComposerHarness(owed: () => communityGateOf(names.gate.state));
  addTearDown(h.dispose);
  await pumpComposer(tester, h);
  return h;
}

void main() {
  setUpAll(initShippedStrings);

  testWidgets('a tap on the field: the name, the guidelines, then the '
      'keyboard (F1–F6)', (tester) async {
    final h = await _ownsBothSteps(tester);

    await tester.tap(composerField);
    await tester.pumpAndSettle();
    expect(find.byType(NameGateForm), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byType(NameGateForm),
        matching: find.byType(TextField),
      ),
      'Dima',
    );
    await tester.pumpAndSettle();
    await _tap(tester, 'Save and continue');
    expect(find.byType(GuidelinesText), findsOneWidget);

    await _tap(tester, 'I agree, continue');
    expect(find.byType(GuidelinesText), findsNothing);
    expect(_focusOf(tester).hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(h.cubit.state.owes, isNull);
  });

  testWidgets('«ليس الآن»: back to a field that still waits (F7) [ar]', (
    tester,
  ) async {
    final rules = GuidelinesHarness();
    addTearDown(rules.dispose);
    // Read once each time the step opens.
    rules.reads([Right(seedGuidelines()), Right(seedGuidelines())]);
    final h = ComposerHarness(owes: CommunityGate.guidelines);
    addTearDown(h.dispose);
    await pumpComposer(tester, h, locale: const Locale('ar'));

    await tester.tap(composerField);
    await tester.pumpAndSettle();
    expect(find.text('إرشادات المجتمع'), findsOneWidget);
    await _tap(tester, 'ليس الآن');

    expect(find.byType(GuidelinesText), findsNothing);
    expect(_focusOf(tester).hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
    // Tapping again asks again.
    await tester.tap(composerField);
    await tester.pumpAndSettle();
    expect(find.byType(GuidelinesText), findsOneWidget);
  });

  testWidgets('the server asks on send: the step, then the text back in a '
      'focused field — not sent again (S5)', (tester) async {
    final rules = GuidelinesHarness();
    addTearDown(rules.dispose);
    rules.accepts([const Right(GuidelinesAcceptance.accepted)]);
    final h = ComposerHarness()..answer = const CommentGuidelinesRequired();
    addTearDown(h.dispose);
    await pumpComposer(tester, h);

    await typeIn(tester, 'A question about istikhara');
    await sendIt(tester);
    await tester.pumpAndSettle();
    expect(find.byType(GuidelinesText), findsOneWidget);

    await _tap(tester, 'I agree, continue');
    expect(composerText(tester), 'A question about istikhara');
    expect(_focusOf(tester).hasFocus, isTrue);
    expect(h.sent, hasLength(1));
  });

  testWidgets('the step left after a refusal: the text stays, and nothing '
      'is sent until the step is taken', (tester) async {
    final rules = GuidelinesHarness();
    addTearDown(rules.dispose);
    final h = ComposerHarness()..answer = const CommentGuidelinesRequired();
    addTearDown(h.dispose);
    await pumpComposer(tester, h);

    await typeIn(tester, 'A question about istikhara');
    await sendIt(tester);
    await tester.pumpAndSettle();
    await _tap(tester, 'Not now');

    expect(composerText(tester), 'A question about istikhara');
    expect(canSend(tester), isFalse);
  });
}
