import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/features/community/domain/entities/community_viewer.dart';
import 'package:qeran/features/community/presentation/widgets/guidelines/guidelines_action_bar.dart';
import 'package:qeran/features/community/presentation/widgets/guidelines/guidelines_text.dart';

import '../../../../core/shipped_strings_rig.dart';
import 'guidelines_rig.dart';

/// The guidelines step as it looks (F5, J3), in both languages: the
/// server's text in the app's language, each rule under its icon, and the
/// choice pinned at the foot.

const _ar = Locale('ar');
const _en = Locale('en');

bool _enabled(WidgetTester tester, String label) =>
    tester
        .widget<QeranButton>(find.widgetWithText(QeranButton, label))
        .onPressed !=
    null;

void main() {
  late GuidelinesHarness harness;

  setUpAll(initShippedStrings);
  setUp(() => harness = GuidelinesHarness());
  tearDown(() => harness.dispose());

  testWidgets('F5 [ar]', (tester) async {
    await openGuidelines(tester, harness, locale: _ar);

    expect(find.text('إرشادات المجتمع'), findsOneWidget);
    expect(
      find.textContaining('المجتمع مساحة لإرشادات خطّابات قِران'),
      findsOneWidget,
    );
    expect(find.text('تحدّث باحترام'), findsOneWidget);
    expect(find.text('لا معلومات تواصل'), findsOneWidget);
    expect(find.byIcon(Icons.handshake_outlined), findsOneWidget);
    expect(find.byIcon(Icons.phone_disabled_outlined), findsOneWidget);
    expect(_enabled(tester, 'أوافق وأتابع'), isTrue);
    expect(_enabled(tester, 'ليس الآن'), isTrue);
  });

  testWidgets('F5 [en]', (tester) async {
    await openGuidelines(tester, harness);

    expect(find.text('Community guidelines'), findsOneWidget);
    expect(find.textContaining('Community is a space'), findsOneWidget);
    expect(find.text('Speak respectfully'), findsOneWidget);
    expect(find.text('No contact details'), findsOneWidget);
    expect(_enabled(tester, 'I agree, continue'), isTrue);
    expect(_enabled(tester, 'Not now'), isTrue);
  });

  for (final (locale, title) in [
    (_ar, 'إرشادات النشر'),
    (_en, 'Posting guidelines'),
  ]) {
    testWidgets('G1: before her first post, her title over the same text '
        '[${locale.languageCode}]', (tester) async {
      await openGuidelines(
        tester,
        harness,
        locale: locale,
        viewer: CommunityViewer.matchmaker,
      );

      expect(find.text(title), findsOneWidget);
    });
  }

  for (final locale in [_ar, _en]) {
    testWidgets('J3 · iPhone SE: the text scrolls under a pinned choice '
        '[${locale.languageCode}]', (tester) async {
      await openGuidelines(
        tester,
        harness,
        locale: locale,
        size: const Size(375, 667),
      );

      expect(tester.takeException(), isNull);
      final bar = find.byType(GuidelinesActionBar);
      expect(tester.getRect(bar).bottom, lessThanOrEqualTo(667));
      // Scrolled to the end, the last rule clears the bar, which stays put.
      await tester.drag(find.byType(GuidelinesText), const Offset(0, -2000));
      await tester.pumpAndSettle();
      final lastRule = find.byIcon(Icons.flag_outlined);
      expect(
        tester.getRect(lastRule).bottom,
        lessThan(tester.getRect(bar).top),
      );
      expect(tester.getRect(bar).bottom, lessThanOrEqualTo(667));
    });
  }
}
