import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_composer.dart';

import '../../../../../core/shipped_strings_rig.dart';
import '../../../fixtures/community_comment_fixtures.dart';
import '../../blocs/composer/composer_cubit_harness.dart';
import 'composer_rig.dart';

void main() {
  late ComposerHarness h;
  setUpAll(initShippedStrings);
  setUp(() => h = ComposerHarness());
  tearDown(() => h.dispose());

  testWidgets('D1: «اكتب تعليقاً…»; sending waits for text', (tester) async {
    await pumpComposer(tester, h, locale: const Locale('ar'));
    expect(find.text('اكتب تعليقاً…'), findsOneWidget);
    expect(canSend(tester), isFalse);

    await typeIn(tester, '   ');
    expect(canSend(tester), isFalse);

    await typeIn(tester, 'سؤال');
    expect(canSend(tester), isTrue);
  });

  testWidgets('D5: sent, the field clears at once', (tester) async {
    await pumpComposer(tester, h);
    await typeIn(tester, 'A question');

    await sendIt(tester);

    expect(composerText(tester), isEmpty);
    expect(h.sent, [('A question', null)]);
  });

  testWidgets('Q8: the field writes in the text\'s own direction and script', (
    tester,
  ) async {
    await pumpComposer(tester, h);

    await typeIn(tester, 'سؤال عن الاستخارة');

    final field = tester.widget<TextField>(composerField);
    expect(field.textDirection, TextDirection.rtl);
    expect(field.style?.fontFamily, 'NotoKufiArabic');
  });

  group('the limit (D3, D4)', () {
    testWidgets('from 400 of 500, the counter', (tester) async {
      await pumpComposer(tester, h);

      await typeIn(tester, 'a' * 399);
      expect(find.text('399 / 500'), findsNothing);

      await typeIn(tester, 'a' * 400);
      expect(find.text('400 / 500'), findsOneWidget);
      expect(canSend(tester), isTrue);
    });

    testWidgets('past 500: danger, and nothing goes', (tester) async {
      await pumpComposer(tester, h);

      await typeIn(tester, 'a' * 501);

      final counter = tester.widget<Text>(find.text('501 / 500'));
      expect(counter.style?.color, QeranColors.danger);
      expect(counter.textDirection, TextDirection.ltr);
      expect(
        tester
            .widget<QeranComposerField>(find.byType(QeranComposerField))
            .error,
        isTrue,
      );
      expect(canSend(tester), isFalse);
    });
  });

  testWidgets('D2: answering a comment — the strip with the name, «اكتب '
      'ردّاً…», and its close', (tester) async {
    await pumpComposer(tester, h, locale: const Locale('ar'));

    h.cubit.replyTo(testComment(id: 10, author: fahad));
    await tester.pump();
    await tester.pump();
    expect(find.text('الرد على'), findsOneWidget);
    expect(find.text(fahad.displayName), findsOneWidget);
    expect(find.text('اكتب ردّاً…'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(find.text('الرد على'), findsNothing);
    expect(find.text('اكتب تعليقاً…'), findsOneWidget);
  });
}
