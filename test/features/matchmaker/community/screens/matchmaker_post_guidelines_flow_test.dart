import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/features/community/domain/entities/post_publish_outcome.dart';
import 'package:qeran/features/community/presentation/screens/community_guidelines_page.dart';
import 'package:qeran/features/matchmaker/community/presentation/screens/post_composer_screen.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../composer_rig.dart';

/// «إرشادات النشر» before her first post (G1, plan §3.1), and the server's
/// backstop when a new version comes out while she writes.
void main() {
  late ComposerHarness h;
  setUpAll(initShippedStrings);
  tearDown(() => h.guidelines.dispose());

  for (final (locale, title, agree, notNow) in [
    (const Locale('ar'), 'إرشادات النشر', 'أوافق وأتابع', 'ليس الآن'),
    (const Locale('en'), 'Posting guidelines', 'I agree, continue', 'Not now'),
  ]) {
    testWidgets('owed [${locale.languageCode}]: «$title» first; «$notNow» '
        'leaves her where she was', (tester) async {
      h = ComposerHarness(owed: true);
      await startComposer(tester, h, locale: locale);

      expect(find.text(title), findsOneWidget);
      await tester.tap(find.text(notNow));
      await tester.pumpAndSettle();

      expect(find.byType(CommunityGuidelinesPage), findsNothing);
      expect(find.byType(PostComposerScreen), findsNothing);
      expect([h.closed, h.result], [true, null]);
    });

    testWidgets('owed [${locale.languageCode}]: «$agree» opens the composer, '
        'and she isn\'t asked again', (tester) async {
      h = ComposerHarness(owed: true);
      await startComposer(tester, h, locale: locale);

      await tester.tap(find.text(agree));
      await tester.pumpAndSettle();
      expect(find.byType(PostComposerScreen), findsOneWidget);
      expect(h.guidelines.acceptedCalls, 1);

      expect(await h.status.owed(), isFalse);
    });
  }

  testWidgets('accepted already: straight to the composer', (tester) async {
    h = ComposerHarness();
    await startComposer(tester, h);

    expect(find.byType(CommunityGuidelinesPage), findsNothing);
    expect(find.byType(PostComposerScreen), findsOneWidget);
  });

  testWidgets('the backstop: a new version came out while she wrote — the '
      'guidelines open over her draft, which is still there after', (
    tester,
  ) async {
    h = ComposerHarness();
    h.publishes(const Right(PostGuidelinesRequired()));
    await startComposer(tester, h);
    await tester.enterText(find.byType(TextField), 'إرشاد');
    await tester.pump();

    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();
    expect(find.text('Posting guidelines'), findsOneWidget);
    await tester.tap(find.text('I agree, continue'));
    await tester.pumpAndSettle();

    expect(find.byType(PostComposerScreen), findsOneWidget);
    expect(find.text('إرشاد'), findsOneWidget);
    verify(() => h.guidelines.accept(any())).called(1);
  });
}
