import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/features/profile/presentation/screens/name/widgets/name_form.dart';

import '../../../../../../core/shipped_strings_rig.dart';

/// Profile › Name as the Phase 2 board updates it (F4): a help line under
/// each name, the placeholder refused as it's typed (F2), and a name the
/// filter refused said under the field (Q10).

const _ar = Locale('ar');
const _en = Locale('en');

Future<void> _pump(
  WidgetTester tester,
  Locale locale, {
  String displayName = 'مستخدم',
  bool isDefaultName = true,
  String? filteredName,
}) => pumpShippedStrings(
  tester,
  locale,
  child: SingleChildScrollView(
    child: NameForm(
      currentDisplayName: displayName,
      currentRealName: null,
      isDefaultName: isDefaultName,
      saving: false,
      filteredName: filteredName,
      onSave: ({required displayName, realName}) {},
    ),
  ),
);

Finder get _displayField => find.byType(TextField).first;

bool _canSave(WidgetTester tester, String label) =>
    tester.widget<QeranButton>(find.widgetWithText(QeranButton, label))
        .onPressed !=
    null;

void main() {
  setUpAll(initShippedStrings);

  testWidgets('each name has its help line [ar]', (tester) async {
    await _pump(tester, _ar);

    expect(find.text('يظهر مع تعليقاتك وردودك في المجتمع.'), findsOneWidget);
    expect(find.text('خاص، لا يظهر لأي أحد في التطبيق.'), findsOneWidget);
    expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
  });

  testWidgets('each name has its help line [en]', (tester) async {
    await _pump(tester, _en);

    expect(
      find.text('Shown with your comments and replies in Community.'),
      findsOneWidget,
    );
    expect(
      find.text('Private. Never shown to anyone in the app.'),
      findsOneWidget,
    );
  });

  testWidgets('the placeholder is refused as it is typed [ar]', (
    tester,
  ) async {
    await _pump(tester, _ar);

    await tester.enterText(_displayField, 'مُسْتَخْدَم');
    await tester.pumpAndSettle();

    expect(find.text('اختر اسماً غير «مستخدم».'), findsOneWidget);
    expect(find.text('يظهر مع تعليقاتك وردودك في المجتمع.'), findsNothing);
    expect(_canSave(tester, 'حفظ التغييرات'), isFalse);
  });

  testWidgets('the placeholder is refused as it is typed [en]', (
    tester,
  ) async {
    await _pump(tester, _en);

    await tester.enterText(_displayField, 'مستخدم جديد');
    await tester.pumpAndSettle();

    expect(find.text('Choose a name other than “مستخدم”.'), findsOneWidget);
    expect(_canSave(tester, 'Save changes'), isFalse);
  });

  testWidgets('a filtered name is said while it is in the field [ar]', (
    tester,
  ) async {
    await _pump(tester, _ar, filteredName: 'اسم مخالف');
    const refused =
        'لا يمكن استخدام هذا الاسم لأنه يخالف إرشادات المجتمع. اختر اسماً آخر.';

    await tester.enterText(_displayField, 'اسم مخالف');
    await tester.pumpAndSettle();
    expect(find.text(refused), findsOneWidget);
    expect(_canSave(tester, 'حفظ التغييرات'), isFalse);

    await tester.enterText(_displayField, 'سارة');
    await tester.pumpAndSettle();
    expect(find.text(refused), findsNothing);
    expect(_canSave(tester, 'حفظ التغييرات'), isTrue);
  });

  testWidgets('a filtered name is said while it is in the field [en]', (
    tester,
  ) async {
    await _pump(tester, _en, filteredName: 'Bad name');

    await tester.enterText(_displayField, 'Bad name');
    await tester.pumpAndSettle();

    expect(
      find.text(
        "This name can't be used because it goes against the community "
        'guidelines. Choose another.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a real name is not mistaken for the placeholder', (
    tester,
  ) async {
    await _pump(tester, _en);

    await tester.enterText(_displayField, 'مستخدمة');
    await tester.pumpAndSettle();

    expect(find.text('Choose a name other than “مستخدم”.'), findsNothing);
    expect(_canSave(tester, 'Save changes'), isTrue);
  });
}
