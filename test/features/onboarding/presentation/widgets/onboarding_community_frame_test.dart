import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/effects/ring_motif.dart';
import 'package:qeran/features/onboarding/presentation/widgets/frames/onboarding_community_card.dart';
import 'package:qeran/features/onboarding/presentation/widgets/frames/onboarding_community_frame.dart';
import 'package:qeran/features/onboarding/presentation/widgets/frames/onboarding_ghost_cards.dart';

import '../../../../core/shipped_strings_rig.dart';

const _ar = Locale('ar');
const _en = Locale('en');

const _phone = Size(412, 892);

/// The sizes the slide must fit without overflowing: a small Android phone,
/// an iPhone SE, the board's frame, and the board's frame on its side.
const _sizes = [Size(360, 640), Size(375, 667), _phone, Size(892, 412)];

const _arabicCopy = [
  'تعلّم قبل أن تخطو',
  'قبل الخِطبة وبعدها، تجد في المجتمع ما تحتاجه من أهل الخبرة: كيف تختار، '
      'وكيف تستعد، وكيف تبدأ حياتك الزوجية.',
  'لا ينشر في المجتمع إلا خطّابات قِران، ودون أي إعلانات.',
  'المجتمع',
  'إرشادات من خطّابات قِران',
  'اختيار شريك الحياة',
  'مقال · هدى',
  'الخِطبة والرؤية الشرعية',
  'فيديو · نورة',
  'الاستعداد للزواج',
  'صور · هدى',
];

const _englishCopy = [
  'Learn before you take the step',
  'Before and after engagement, Community gives you advice from people with '
      'experience: how to choose, how to prepare, and how to begin married '
      'life.',
  "Only Qeran's matchmakers publish in Community, and there are no ads.",
  'Community',
  "Guidance from Qeran's matchmakers",
  'Choosing a spouse',
  'Article · Huda',
  'Engagement and the shar‘i viewing',
  'Video · Noura',
  'Preparing for marriage',
  'Images · Huda',
];

void _setPhone(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _pumpFrame(
  WidgetTester tester,
  Locale locale, {
  VoidCallback? onNext,
}) async {
  await pumpShippedStrings(
    tester,
    locale,
    child: OnboardingCommunityFrame(
      dotCount: 3,
      activeDot: 0,
      onDot: (_) {},
      onNext: onNext ?? () {},
    ),
  );
}

Rect _firstGhost(WidgetTester tester) => tester.getRect(
  find
      .descendant(
        of: find.byType(OnboardingGhostCards),
        matching: find.byType(Container),
      )
      .first,
);

void main() {
  setUpAll(initShippedStrings);

  testWidgets('Arabic: the copy and the card show the shipped strings', (
    tester,
  ) async {
    _setPhone(tester, _phone);
    await _pumpFrame(tester, _ar);

    for (final text in _arabicCopy) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('English: the copy and the card show the shipped strings', (
    tester,
  ) async {
    _setPhone(tester, _phone);
    await _pumpFrame(tester, _en);

    for (final text in _englishCopy) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  for (final locale in [_ar, _en]) {
    testWidgets('fits every phone size without overflow — $locale', (
      tester,
    ) async {
      for (final size in _sizes) {
        _setPhone(tester, size);
        await _pumpFrame(tester, locale);

        expect(tester.takeException(), isNull, reason: '$size');
      }
    });
  }

  testWidgets('English: the rings sit at the right, the first ghost at the '
      'left edge', (tester) async {
    _setPhone(tester, _phone);
    await _pumpFrame(tester, _en);

    expect(tester.getRect(find.byType(RingMotif)).center.dx, greaterThan(206));
    expect(_firstGhost(tester).left, lessThan(0));
  });

  testWidgets('Arabic: the rings sit at the left, the first ghost at the '
      'right edge', (tester) async {
    _setPhone(tester, _phone);
    await _pumpFrame(tester, _ar);

    expect(tester.getRect(find.byType(RingMotif)).center.dx, lessThan(206));
    expect(_firstGhost(tester).right, greaterThan(412));
  });

  testWidgets('a short screen shrinks the card whole instead of clipping it', (
    tester,
  ) async {
    _setPhone(tester, const Size(360, 640));
    await _pumpFrame(tester, _ar);

    final card = find.byType(OnboardingCommunityCard);
    expect(tester.getRect(card).height, lessThan(tester.getSize(card).height));
  });

  testWidgets('the board\'s frame draws the card at full size', (tester) async {
    _setPhone(tester, _phone);
    await _pumpFrame(tester, _ar);

    final card = find.byType(OnboardingCommunityCard);
    expect(
      tester.getRect(card).height,
      moreOrLessEquals(tester.getSize(card).height),
    );
  });

  testWidgets('screen readers get the copy, not the illustration', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    _setPhone(tester, _phone);
    await _pumpFrame(tester, _ar);

    expect(find.bySemanticsLabel(_arabicCopy[0]), findsOneWidget);
    expect(find.bySemanticsLabel(_arabicCopy[2]), findsOneWidget);
    for (final text in _arabicCopy.skip(3)) {
      expect(find.bySemanticsLabel(text), findsNothing, reason: text);
    }
    semantics.dispose();
  });

  testWidgets('«التالي» calls onNext, and the first page has no back control', (
    tester,
  ) async {
    var nexts = 0;
    _setPhone(tester, _phone);
    await _pumpFrame(tester, _ar, onNext: () => nexts++);

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    expect(nexts, 1);
    expect(find.byIcon(Icons.arrow_back_ios_rounded), findsNothing);
  });
}
