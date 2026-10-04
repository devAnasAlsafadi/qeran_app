import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/widgets/qeran_app_bar.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/guidelines_acceptance.dart';
import 'package:qeran/features/community/presentation/widgets/guidelines/guidelines_text.dart';

import '../../../../core/shipped_strings_rig.dart';
import 'guidelines_rig.dart';

/// What the guidelines step does (F5–F7, S6, W3): true once the member has
/// agreed, false otherwise — and nothing is agreed to unseen.

const _agree = 'I agree, continue';

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(QeranButton, label));
  await tester.pumpAndSettle();
}

void main() {
  late GuidelinesHarness harness;

  setUpAll(initShippedStrings);
  setUp(() => harness = GuidelinesHarness());
  tearDown(() => harness.dispose());

  testWidgets('agreeing sends the version read and answers true (F6)', (
    tester,
  ) async {
    harness.accepts([const Right(GuidelinesAcceptance.accepted)]);
    await openGuidelines(tester, harness);

    await _tap(tester, _agree);

    verify(() => harness.accept(1)).called(1);
    expect(harness.acceptedCalls, 1);
    expect(harness.result, isTrue);
    expect(find.byType(GuidelinesText), findsNothing);
  });

  testWidgets('«Not now» answers false and agrees to nothing (F7)', (
    tester,
  ) async {
    await openGuidelines(tester, harness);

    await _tap(tester, 'Not now');

    expect(harness.result, isFalse);
    verifyNever(() => harness.accept(any()));
  });

  testWidgets('going back answers false too', (tester) async {
    await openGuidelines(tester, harness);

    await tester.tap(find.byType(QeranBackButton));
    await tester.pumpAndSettle();

    expect(harness.result, isFalse);
  });

  testWidgets('a failed agreement is a toast, and the step stays', (
    tester,
  ) async {
    harness.accepts([const Left(OfflineFailure())]);
    await openGuidelines(tester, harness);

    await _tap(tester, _agree);

    expect(
      find.text("Couldn't save your agreement. Try again."),
      findsOneWidget,
    );
    expect(harness.result, isNull);
    expect(harness.acceptedCalls, 0);
    // Let the toast leave before the test ends.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('text that fails to load can be tried again; until then '
      'nothing can be agreed to (S6)', (tester) async {
    harness.reads([const Left(OfflineFailure()), Right(seedGuidelines())]);
    await openGuidelines(tester, harness);

    expect(find.text("Couldn't load the guidelines"), findsOneWidget);
    final agree = tester.widget<QeranButton>(
      find.widgetWithText(QeranButton, _agree),
    );
    expect(agree.onPressed, isNull);

    await _tap(tester, 'Try again');
    expect(find.byType(GuidelinesText), findsOneWidget);
  });

  testWidgets('text changed meanwhile: the new text, asked again (W3)', (
    tester,
  ) async {
    harness.reads([
      Right(seedGuidelines()),
      Right(seedGuidelines(version: 2, introEn: 'The updated guidelines.')),
    ]);
    harness.accepts([
      const Right(GuidelinesAcceptance.outdated),
      const Right(GuidelinesAcceptance.accepted),
    ]);
    await openGuidelines(tester, harness);

    await _tap(tester, _agree);
    expect(find.text('The updated guidelines.'), findsOneWidget);
    expect(harness.result, isNull);

    await _tap(tester, _agree);
    verify(() => harness.accept(2)).called(1);
    expect(harness.result, isTrue);
  });
}
