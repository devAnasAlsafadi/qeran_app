import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/post_publish_outcome.dart';
import 'package:qeran/features/matchmaker/community/presentation/screens/post_composer_screen.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../../community/fixtures/community_post_fixtures.dart';
import '../composer_rig.dart';

const _ar = Locale('ar');
const _en = Locale('en');

final _copy = {
  _ar: (
    title: 'منشور جديد',
    publish: 'نشر',
    hint: 'اكتبي إرشاداً للأعضاء…',
    audience: 'يظهر لكل الأعضاء والخطّابات',
    tooLong: 'النص أطول من الحد المسموح.',
    discardTitle: 'تجاهل المنشور؟',
    discardBody: 'لن يُحفظ ما كتبتِه أو أضفتِه.',
    discard: 'تجاهل',
    keep: 'متابعة الكتابة',
    rejected:
        'لا يمكن نشر هذا المنشور لأنه يخالف إرشادات النشر. عدّلي النص '
        'وحاولي مرة أخرى.',
    failed: 'تعذّر رفع المنشور. تحقّقي من اتصالكِ.',
    retry: 'إعادة المحاولة',
  ),
  _en: (
    title: 'New post',
    publish: 'Publish',
    hint: 'Write guidance for members…',
    audience: 'Visible to all members and matchmakers',
    tooLong: 'The text is longer than allowed.',
    discardTitle: 'Discard this post?',
    discardBody: "What you've written or added won't be saved.",
    discard: 'Discard',
    keep: 'Keep writing',
    rejected:
        "This post can't be published because it goes against the posting "
        'guidelines. Edit it and try again.',
    failed: "Couldn't upload your post. Check your connection.",
    retry: 'Retry',
  ),
};

bool _publishOn(WidgetTester tester, String label) {
  final button = tester.widget<QeranButton>(
    find.widgetWithText(QeranButton, label),
  );
  return button.onPressed != null && !button.loading;
}

void main() {
  late ComposerHarness h;
  setUpAll(initShippedStrings);
  setUp(() => h = ComposerHarness());
  tearDown(() => h.guidelines.dispose());

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
  }

  for (final locale in [_ar, _en]) {
    final t = _copy[locale]!;

    testWidgets(
      'C1 [${locale.languageCode}]: «${t.title}», a ×, «${t.publish}» '
      'off, her line, the counter from 0',
      (tester) async {
        await startComposer(tester, h, locale: locale);

        expect(find.byType(PostComposerScreen), findsOneWidget);
        expect(find.text(t.title), findsOneWidget);
        expect(find.byIcon(Icons.close_rounded), findsOneWidget);
        expect(_publishOn(tester, t.publish), isFalse);
        expect(find.text(t.audience), findsOneWidget);
        expect(find.text(t.hint), findsOneWidget);
        expect(find.text('0 / 2000'), findsOneWidget);
      },
    );

    testWidgets('C7 [${locale.languageCode}]: past the limit, the counter '
        'and the line say so, and «${t.publish}» is off', (tester) async {
      h.limitText(5);
      await startComposer(tester, h, locale: locale);

      await type(tester, 'abcdef');

      expect(find.text(t.tooLong), findsOneWidget);
      expect(find.text('6 / 5'), findsOneWidget);
      expect(_publishOn(tester, t.publish), isFalse);
    });

    testWidgets('BA-A7 [${locale.languageCode}]: the filter refuses — the '
        'text stays, the notice says why, «${t.publish}» stays on', (
      tester,
    ) async {
      h.publishes(const Right(PostRejected()));
      await startComposer(tester, h, locale: locale);

      await type(tester, 'تواصل 0599123456');
      await tester.tap(find.text(t.publish));
      await tester.pumpAndSettle();

      expect(find.text(t.rejected), findsOneWidget);
      expect(find.text('تواصل 0599123456'), findsOneWidget);
      expect(_publishOn(tester, t.publish), isTrue);
    });

    testWidgets('D3 [${locale.languageCode}]: it didn\'t get through — the '
        'strip; Retry sends the same request, and it closes', (tester) async {
      h.publishes(const Left(OfflineFailure()));
      await startComposer(tester, h, locale: locale);

      await type(tester, 'إرشاد');
      await tester.tap(find.text(t.publish));
      await tester.pumpAndSettle();
      expect(find.text(t.failed), findsOneWidget);

      h.publishes(Right(PostPublished(testPost(id: 31))));
      await tester.tap(find.text(t.retry));
      await tester.pumpAndSettle();

      expect(h.sentIds, ['req-1', 'req-1']);
      expect(h.result?.id, 31);
    });

    testWidgets('C11 [${locale.languageCode}]: × on a draft asks; «${t.keep}» '
        'stays, «${t.discard}» closes', (tester) async {
      await startComposer(tester, h, locale: locale);
      await type(tester, 'إرشاد');

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text(t.discardTitle), findsOneWidget);
      expect(find.text(t.discardBody), findsOneWidget);
      await tester.tap(find.text(t.keep));
      await tester.pumpAndSettle();
      expect(find.byType(PostComposerScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.discard));
      await tester.pumpAndSettle();
      expect(find.byType(PostComposerScreen), findsNothing);
      expect([h.closed, h.result], [true, null]);
    });
  }

  testWidgets('C2: typing turns «Publish» on; Arabic runs right to left in '
      'the English UI (D13)', (tester) async {
    await startComposer(tester, h);

    await type(tester, 'الاستخارة');

    expect(_publishOn(tester, 'Publish'), isTrue);
    expect(find.text('9 / 2000'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).textDirection,
      TextDirection.rtl,
    );
  });

  testWidgets('C11: an empty draft closes at once, nothing asked', (
    tester,
  ) async {
    await startComposer(tester, h);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(PostComposerScreen), findsNothing);
    expect(find.text('Discard this post?'), findsNothing);
  });

  testWidgets('D5: published, it closes with her post, the text trimmed', (
    tester,
  ) async {
    h.publishes(Right(PostPublished(testPost(id: 31))));
    await startComposer(tester, h);

    await type(tester, '  إرشاد  ');
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    expect(find.byType(PostComposerScreen), findsNothing);
    expect(h.result?.id, 31);
  });
}
