import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_page_indicator.dart';
import 'package:qeran/features/community/domain/entities/community_media.dart';
import 'package:qeran/features/community/presentation/widgets/post_card/post_video_tile.dart';

import '../../../../../core/shipped_strings_rig.dart';
import '../../../../auth/presentation/fake_session.dart';
import '../../../fixtures/community_post_fixtures.dart';

/// The card's media width: 358 less 12 on each side.
const _frameWidth = 334.0;

Future<void> _pump(
  WidgetTester tester,
  CommunityVideo video, {
  TextDirection direction = TextDirection.ltr,
}) => pumpShippedStrings(
  tester,
  direction == TextDirection.ltr ? const Locale('en') : const Locale('ar'),
  child: withSession(
    Center(
      child: SizedBox(
        width: 358,
        child: PostVideoTile(postId: 1, video: video),
      ),
    ),
  ),
);

Size _frame(WidgetTester tester) => tester.getSize(find.byType(AspectRatio));

void main() {
  setUpAll(initShippedStrings);

  group('the frame: its own ratio, clamped 4:5 – 16:9 (BA-B1–B3)', () {
    const cases = {
      (1080, 1920): 0.8, // vertical: wine bars at the sides
      (1080, 1080): 1.0,
      (1920, 1080): 16 / 9,
      (2560, 1080): 16 / 9, // 21:9: bars above and below
      (0, 0): 16 / 9, // no size
    };
    for (final MapEntry(key: (w, h), value: ratio) in cases.entries) {
      testWidgets('$w × $h → $ratio', (tester) async {
        await _pump(tester, testVideo(width: w, height: h));

        expect(_frame(tester).width, _frameWidth);
        expect(_frame(tester).height, closeTo(_frameWidth / ratio, 0.01));
      });
    }
  });

  testWidgets('the poster: contained, never cropped, and sent with no token', (
    tester,
  ) async {
    await _pump(tester, testVideo());

    final poster = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(poster.imageUrl, signedPoster);
    expect(poster.fit, BoxFit.contain);
    expect(poster.httpHeaders, isNull);
  });

  testWidgets('no poster: the wine frame and the play disc still show', (
    tester,
  ) async {
    await _pump(tester, testVideo(posterUrl: null));

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });

  testWidgets('the length, left to right, at the frame\'s start', (
    tester,
  ) async {
    for (final direction in TextDirection.values) {
      // A fresh tree, so the language (and its direction) starts anew.
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, testVideo(), direction: direction);

      final pill = tester.getCenter(find.byType(QeranOverlayPill));
      final middle = tester.getCenter(find.byType(AspectRatio));
      expect(find.text('0:52'), findsOneWidget);
      expect(
        pill.dx < middle.dx,
        direction == TextDirection.ltr,
        reason: '$direction',
      );
    }
  });

  testWidgets('no length from the server: no pill', (tester) async {
    await _pump(tester, testVideo(duration: Duration.zero));

    expect(find.byType(QeranOverlayPill), findsNothing);
  });
}
