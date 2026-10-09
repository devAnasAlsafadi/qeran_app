import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_composer.dart';
import 'package:qeran/features/community/domain/entities/comment_submit_outcome.dart';

import '../../../../../core/shipped_strings_rig.dart';
import '../../blocs/composer/composer_cubit_harness.dart';
import 'composer_rig.dart';

void main() {
  late ComposerHarness h;
  setUpAll(initShippedStrings);
  setUp(() => h = ComposerHarness());
  tearDown(() => h.dispose());

  testWidgets('D8: refused by the filter — the banner, the text back', (
    tester,
  ) async {
    h.answer = const CommentFiltered();
    await pumpComposer(tester, h);
    await typeIn(tester, 'Message me');

    await sendIt(tester);

    expect(
      find.text(
        "This comment can't be posted because it goes against the community "
        'guidelines. Edit it and try again.',
      ),
      findsOneWidget,
    );
    expect(composerText(tester), 'Message me');
  });

  testWidgets('D9: rate limited — told so, the text back, sending rests', (
    tester,
  ) async {
    h.answer = const CommentRateLimited(retryAfter: Duration(minutes: 1));
    await pumpComposer(tester, h);
    await typeIn(tester, 'Again');

    await sendIt(tester);

    expect(
      find.text(
        "You've posted a lot in a short time. Wait a moment and try again.",
      ),
      findsOneWidget,
    );
    expect(composerText(tester), 'Again');
    expect(canSend(tester), isFalse);

    await tester.pump(const Duration(minutes: 1));
    await tester.pump();
    expect(canSend(tester), isTrue);
  });

  testWidgets('C10: a member not approved yet — why, and no field', (
    tester,
  ) async {
    await pumpComposer(tester, h, readOnly: true);

    expect(
      find.text('You can comment and reply once your profile is approved.'),
      findsOneWidget,
    );
    expect(composerField, findsNothing);
  });

  testWidgets('what the member typed meanwhile is not overwritten', (
    tester,
  ) async {
    h.answer = const CommentFiltered();
    await pumpComposer(tester, h);
    await typeIn(tester, 'First');
    await tester.tap(find.byType(QeranSendButton));
    await tester.enterText(composerField, 'Second');

    await tester.pump();
    await tester.pump();

    expect(composerText(tester), 'Second');
  });
}
