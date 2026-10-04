import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/widgets/qeran_app_bar.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/presentation/widgets/name_gate/name_gate_form.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_state.dart';

import '../../../../core/shipped_strings_rig.dart';
import 'name_gate_rig.dart';

/// What the name step does (F3, Q10): it sends the display name alone and
/// answers true once one is saved — or false when the member goes back.

const _save = 'Save and continue';
const _refused =
    "This name can't be used because it goes against the community "
    'guidelines. Choose another.';

Finder get _field => find.byType(TextField);

Future<void> _type(WidgetTester tester, String name) async {
  await tester.enterText(_field, name);
  await tester.pumpAndSettle();
}

Future<void> _tapSave(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(QeranButton, _save));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initShippedStrings);

  testWidgets('saving sends the display name alone and answers true', (
    tester,
  ) async {
    final harness = NameGateHarness(
      profile: gateProfile(realName: 'ديما الصفدي'),
    );
    addTearDown(harness.dispose);
    harness.answerSaves([Right(gateProfile(name: 'Dima'))]);
    await openNameGate(tester, harness);

    await _type(tester, '  Dima  ');
    await _tapSave(tester);

    // The real name on file is left alone: no key, not a blank.
    verify(
      () => harness.updateProfile(displayName: 'Dima', realName: null),
    ).called(1);
    expect(harness.result, isTrue);
    expect(find.byType(NameGateForm), findsNothing);
    // The app's gate has the new name — the composer's mirror reads it.
    final gate = harness.gate.state as ProfileGateResolved;
    expect(gate.isDefaultName, isFalse);
  });

  testWidgets('going back answers false and saves nothing', (tester) async {
    final harness = NameGateHarness();
    addTearDown(harness.dispose);
    await openNameGate(tester, harness);

    await _type(tester, 'Dima');
    await tester.tap(find.byType(QeranBackButton));
    await tester.pumpAndSettle();

    expect(harness.result, isFalse);
    verifyNever(
      () => harness.updateProfile(
        displayName: any(named: 'displayName'),
        realName: any(named: 'realName'),
      ),
    );
  });

  testWidgets('a member already named goes straight through', (tester) async {
    final harness = NameGateHarness(profile: gateProfile(name: 'سارة'));
    addTearDown(harness.dispose);

    await openNameGate(tester, harness);

    expect(harness.result, isTrue);
    expect(find.byType(NameGateForm), findsNothing);
  });

  testWidgets('a filtered name is said under the field (Q10)', (tester) async {
    final harness = NameGateHarness();
    addTearDown(harness.dispose);
    harness.answerSaves([
      const Left(
        CodedServerFailure(
          message: 'الاسم مخالف',
          errorCode: 'CONTENT_NOT_ALLOWED',
        ),
      ),
    ]);
    await openNameGate(tester, harness);

    await _type(tester, 'Bad name');
    await _tapSave(tester);

    expect(harness.result, isNull);
    expect(find.text(_refused), findsOneWidget);
    expect(
      tester
          .widget<QeranButton>(find.widgetWithText(QeranButton, _save))
          .onPressed,
      isNull,
    );

    await _type(tester, 'Dima');
    expect(find.text(_refused), findsNothing);
  });

  testWidgets('any other refusal is a toast, and the step stays', (
    tester,
  ) async {
    final harness = NameGateHarness();
    addTearDown(harness.dispose);
    harness.answerSaves([const Left(ServerFailure(message: 'رسالة الخادم'))]);
    await openNameGate(tester, harness);

    await _type(tester, 'Dima');
    await _tapSave(tester);

    expect(find.text('رسالة الخادم'), findsOneWidget);
    expect(harness.result, isNull);
    expect(find.byType(NameGateForm), findsOneWidget);
    // Let the toast leave before the test ends.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('a profile that fails to load can be tried again', (
    tester,
  ) async {
    final harness = NameGateHarness();
    addTearDown(harness.dispose);
    final answers = [
      const Left<Failure, Never>(ServerFailure(message: 'errors.generic')),
    ];
    when(() => harness.getMyProfile()).thenAnswer(
      (_) async => answers.isEmpty ? Right(gateProfile()) : answers.removeAt(0),
    );
    await openNameGate(tester, harness);

    expect(find.byType(NameGateForm), findsNothing);
    await tester.tap(find.widgetWithText(QeranButton, 'Try again'));
    await tester.pumpAndSettle();

    expect(find.byType(NameGateForm), findsOneWidget);
  });
}
