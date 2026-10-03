import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/features/community/domain/entities/community_media.dart';
import 'package:qeran/features/community/presentation/widgets/post_card/community_post_card.dart';
import 'package:qeran/features/community/presentation/widgets/post_card/post_image_set.dart';
import 'package:qeran/features/community/presentation/widgets/post_card/post_video_tile.dart';

import '../../../../../core/shipped_strings_rig.dart';
import '../../../fixtures/community_post_fixtures.dart';
import 'post_card_rig.dart';

/// Whether [text] is laid out cut short of its full width.
bool _cut(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  return paragraph.getMaxIntrinsicWidth(double.infinity) >
      paragraph.size.width + 0.01;
}

void main() {
  setUpAll(initShippedStrings);

  testWidgets('S1: only the discussion half opens the post', (tester) async {
    var opened = 0;
    await pumpCard(tester, testPost(), onOpenDiscussion: () => opened++);

    await tester.tap(find.text(istikhara));
    await tester.tap(find.text(huda.displayName));
    expect(opened, 0);

    await tester.tap(find.text('Discuss'));
    expect(opened, 1);
  });

  testWidgets('on the post screen: «Discussion» in muted ink, no chevron, '
      'not a way in; the text whole', (tester) async {
    var opened = 0;
    await pumpCard(
      tester,
      testPost(text: longText, commentCount: 14),
      mode: CommunityPostCardMode.detail,
      onOpenDiscussion: () => opened++,
    );

    final label = tester.widget<Text>(find.text('Discussion'));
    expect(label.style?.color, QeranColors.inkMuted);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    await tester.tap(find.text('Discussion'));
    expect(opened, 0);
    expect(find.text('See more'), findsNothing);
  });

  testWidgets('with no comments, the post screen still says «Discussion»', (
    tester,
  ) async {
    await pumpCard(tester, testPost(), mode: CommunityPostCardMode.detail);

    expect(find.text('Discussion'), findsOneWidget);
    expect(find.text('Discuss'), findsNothing);
  });

  testWidgets('A18: a long Arabic name in the English UI is cut at its own '
      'end; the chip stays whole', (tester) async {
    await pumpCard(tester, testPost(author: ummAbdulrahman), width: 300);

    final name = ummAbdulrahman.displayName;
    expect(
      tester.renderObject<RenderParagraph>(find.text(name)).textDirection,
      TextDirection.rtl,
    );
    expect(_cut(tester, name), isTrue);
    expect(_cut(tester, 'Matchmaker'), isFalse);
  });

  testWidgets('photos and a video take their place in the card', (
    tester,
  ) async {
    await pumpCard(
      tester,
      testPost(media: CommunityImageSet([testImage(), testImage()])),
    );
    expect(find.byType(PostImageSet), findsOneWidget);

    await pumpCard(tester, testPost(media: CommunitySingleVideo(testVideo())));
    expect(find.byType(PostVideoTile), findsOneWidget);
  });

  group('BA-C: the post screen keeps the clamped video frame', () {
    const cases = {(1080, 1920): 0.8, (1080, 1080): 1.0, (1920, 1080): 16 / 9};
    for (final MapEntry(key: (w, h), value: ratio) in cases.entries) {
      testWidgets('$w × $h → $ratio', (tester) async {
        await pumpCard(
          tester,
          testPost(
            media: CommunitySingleVideo(testVideo(width: w, height: h)),
          ),
          mode: CommunityPostCardMode.detail,
        );

        final frame = tester.getSize(find.byType(AspectRatio));
        expect(frame.width, 334);
        expect(frame.height, closeTo(334 / ratio, 0.01));
      });
    }
  });
}
