import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/presentation/widgets/post_card/post_card_text.dart';

import '../../../../../core/shipped_strings_rig.dart';
import '../../../fixtures/community_post_fixtures.dart';

/// The text in a card-wide column, in [locale]'s UI.
Future<void> _pump(
  WidgetTester tester,
  String text, {
  Locale locale = const Locale('en'),
  bool collapsible = true,
}) => pumpShippedStrings(
  tester,
  locale,
  // A whole long post is taller than the screen: the feed scrolls.
  child: SingleChildScrollView(
    child: Center(
      child: SizedBox(
        width: 358,
        child: PostCardText(text, collapsible: collapsible),
      ),
    ),
  ),
);

/// One line at any width, even in the test font's square glyphs.
const _short = 'قبل الجلسة الأولى';

/// The post's own paragraph (not the See more label).
RenderParagraph _post(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text));

Text _postText(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text));

void main() {
  setUpAll(initShippedStrings);

  testWidgets('a short text: whole, no See more', (tester) async {
    await _pump(tester, _short);

    expect(_postText(tester, _short).maxLines, isNull);
    expect(find.text('See more'), findsNothing);
  });

  testWidgets('a long text in the feed: four lines and See more (A2), which '
      'opens it in place (A3)', (tester) async {
    await _pump(tester, longText);

    expect(_postText(tester, longText).maxLines, PostCardText.collapsedLines);
    expect(_post(tester, longText).didExceedMaxLines, isTrue);

    await tester.tap(find.text('See more'));
    await tester.pumpAndSettle();

    expect(_postText(tester, longText).maxLines, isNull);
    expect(find.text('See more'), findsNothing);
  });

  testWidgets('in Arabic: «عرض المزيد»', (tester) async {
    await _pump(tester, longText, locale: const Locale('ar'));

    expect(find.text('عرض المزيد'), findsOneWidget);
  });

  testWidgets('on the post screen: always whole', (tester) async {
    await _pump(tester, longText, collapsible: false);

    expect(_postText(tester, longText).maxLines, isNull);
    expect(find.text('See more'), findsNothing);
  });

  // Long-form reading: more leading than the body style's 1.55, in the feed
  // and on the post screen alike.
  for (final collapsible in [true, false]) {
    testWidgets('read at the reading line height, 1.75 '
        '[${collapsible ? 'feed' : 'post screen'}]', (tester) async {
      await _pump(tester, _short, collapsible: collapsible);

      expect(_postText(tester, _short).style?.height, 1.75);
    });
  }

  group('its own direction and script (D13, A21)', () {
    testWidgets('an Arabic post in the English UI', (tester) async {
      await _pump(tester, _short);

      expect(_post(tester, _short).textDirection, TextDirection.rtl);
      expect(_postText(tester, _short).style?.fontFamily, 'NotoKufiArabic');
    });

    testWidgets('an English post in the Arabic UI', (tester) async {
      await _pump(tester, englishText, locale: const Locale('ar'));

      expect(_post(tester, englishText).textDirection, TextDirection.ltr);
      expect(_postText(tester, englishText).style?.fontFamily, 'Montserrat');
    });
  });
}
