import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/features/community/presentation/widgets/name_gate/name_gate_preview.dart';

import '../../../../core/shipped_strings_rig.dart';
import 'name_gate_rig.dart';

/// The name step as it looks (F1–F3), in both languages.

const _ar = Locale('ar');
const _en = Locale('en');

Finder get _field => find.byType(TextField);

Finder _inPreview(String text) => find.descendant(
  of: find.byType(NameGatePreview),
  matching: find.text(text),
);

bool _canSave(WidgetTester tester, String label) =>
    tester
        .widget<QeranButton>(find.widgetWithText(QeranButton, label))
        .onPressed !=
    null;

void main() {
  late NameGateHarness harness;

  setUpAll(initShippedStrings);
  setUp(() => harness = NameGateHarness());
  tearDown(() => harness.dispose());

  testWidgets('F1 · empty [ar]', (tester) async {
    await openNameGate(tester, harness, locale: _ar);

    expect(find.text('اسمك في المجتمع'), findsOneWidget);
    expect(find.text('اختر اسماً يظهر مع تعليقاتك'), findsOneWidget);
    expect(
      find.text(
        'اسمك الظاهر الحالي هو «مستخدم»، وهو الاسم الافتراضي. اختر اسماً '
        'يعرّفك قبل أن تشارك في النقاش.',
      ),
      findsOneWidget,
    );
    expect(find.text('يظهر مع تعليقاتك وردودك في المجتمع.'), findsOneWidget);
    expect(find.text('اسمك الحقيقي خاص ولا يظهر لأي أحد.'), findsOneWidget);
    expect(find.text('هكذا سيظهر اسمك'), findsOneWidget);
    // Until a name is typed, the preview shows the placeholder.
    expect(_inPreview('مستخدم'), findsOneWidget);
    expect(_inPreview('· الآن'), findsOneWidget);
    expect(_inPreview('تعليقك يظهر هنا'), findsOneWidget);
    expect(_canSave(tester, 'حفظ ومتابعة'), isFalse);
  });

  testWidgets('F1 · empty [en]', (tester) async {
    await openNameGate(tester, harness);

    expect(find.text('Your name in Community'), findsOneWidget);
    expect(
      find.text('Choose the name shown with your comments'),
      findsOneWidget,
    );
    expect(
      find.text('Your real name is private and never shown.'),
      findsOneWidget,
    );
    expect(find.text('How your name will appear'), findsOneWidget);
    expect(_inPreview('· Just now'), findsOneWidget);
    expect(_inPreview('Your comment appears here'), findsOneWidget);
    expect(_canSave(tester, 'Save and continue'), isFalse);
  });

  testWidgets('F2 · still «مستخدم» [ar]', (tester) async {
    await openNameGate(tester, harness, locale: _ar);

    await tester.enterText(_field, 'مستخدم');
    await tester.pumpAndSettle();

    expect(find.text('اختر اسماً غير «مستخدم».'), findsOneWidget);
    expect(find.text('يظهر مع تعليقاتك وردودك في المجتمع.'), findsNothing);
    expect(_canSave(tester, 'حفظ ومتابعة'), isFalse);
  });

  testWidgets('F3 · valid: the preview takes the name [en]', (tester) async {
    await openNameGate(tester, harness);

    await tester.enterText(_field, 'Dima');
    await tester.pumpAndSettle();

    expect(_inPreview('Dima'), findsOneWidget);
    expect(_inPreview('D'), findsOneWidget);
    expect(_canSave(tester, 'Save and continue'), isTrue);
  });

  testWidgets('F3 · an Arabic name keeps its own direction in English', (
    tester,
  ) async {
    await openNameGate(tester, harness);

    await tester.enterText(_field, 'ديما');
    await tester.pumpAndSettle();

    final name = tester.widget<Text>(_inPreview('ديما'));
    expect(name.textDirection, TextDirection.rtl);
  });

  for (final locale in [_ar, _en]) {
    testWidgets('the private line sits in line with the help line '
        '[${locale.languageCode}]', (tester) async {
      await openNameGate(tester, harness, locale: locale);

      final help = tester.getRect(find.byIcon(Icons.forum_outlined));
      final private = tester.getRect(find.byIcon(Icons.lock_outline_rounded));
      if (locale == _ar) {
        expect(private.right, moreOrLessEquals(help.right));
      } else {
        expect(private.left, moreOrLessEquals(help.left));
      }
    });

    testWidgets('fits an iPhone SE [${locale.languageCode}]', (tester) async {
      await openNameGate(
        tester,
        harness,
        locale: locale,
        size: const Size(375, 667),
      );

      await tester.enterText(_field, 'مستخدم');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
