import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/community/domain/entities/picked_video.dart';
import 'package:qeran/features/community/presentation/video/community_video_player.dart';
import 'package:qeran/features/community/presentation/widgets/video/video_layers.dart';
import 'package:qeran/features/matchmaker/community/presentation/widgets/composer/composer_video_preview.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../../community/presentation/widgets/video/video_rig.dart';
import '../composer_media_fakes.dart';

PickedVideo _video({int width = 1080, int height = 1920}) => PickedVideo(
  path: 'clip.mp4',
  container: VideoContainer.mp4,
  info: clip(width: width, height: height),
);

void main() {
  setUpAll(initShippedStrings);

  group('BA-D: the frame', () {
    test('vertical 9:16 → a 4:5 frame, 208 × 260 (D1)', () {
      expect(composerPreviewSize(350, 1080, 1920), const Size(208, 260));
    });

    test('square → 260 × 260 (D2)', () {
      expect(composerPreviewSize(350, 1080, 1080), const Size(260, 260));
    });

    test('landscape 16:9 → the full width (D3); 21:9 is clamped to 16:9', () {
      final wide = composerPreviewSize(350, 1920, 1080);
      expect(wide.width, 350);
      expect(wide.height, closeTo(196.9, 0.1));
      expect(composerPreviewSize(350, 2520, 1080), wide);
    });

    test('between square and 16:9: 260 high, as long as it fits (18.10)', () {
      expect(composerPreviewSize(350, 1350, 1080), const Size(325, 260));
      final justOver = composerPreviewSize(350, 1091, 1080);
      expect(justOver.height, 260);
      expect(justOver.width, closeTo(262.6, 0.1));
    });

    test('wider than there is room for: the full width at its ratio', () {
      final threeTwo = composerPreviewSize(350, 1620, 1080);
      expect(threeTwo.width, 350);
      expect(threeTwo.height, closeTo(233.3, 0.1));
      expect(composerPreviewSize(200, 1080, 1080), const Size(200, 200));
    });

    test('16:9 takes the full width on a wide screen too', () {
      expect(composerPreviewSize(600, 1920, 1080), const Size(600, 337.5));
    });
  });

  group('the player', () {
    late FakePlayer player;
    setUp(() {
      sl.registerSingleton<CommunityLocalVideoPlayerFactory>((path) {
        return player = FakePlayer(Uri.file(path));
      });
    });
    tearDown(sl.reset);

    Future<void> pump(WidgetTester tester, {VoidCallback? onRemove}) async {
      await pumpShippedStrings(
        tester,
        const Locale('en'),
        child: Scaffold(
          body: ComposerVideoPreview(video: _video(), onRemove: onRemove),
        ),
      );
    }

    testWidgets('her file, initialized at once; the disc plays it, a tap on '
        'the picture pauses it; its length at the bottom start', (
      tester,
    ) async {
      await pump(tester);
      expect(player.url, Uri.file('clip.mp4'));
      expect(player.calls, ['initialize']);
      expect(find.text('0:30'), findsOneWidget);

      await tester.tap(find.byType(VideoPlayDisc));
      await tester.pump();
      expect(find.byType(VideoPlayDisc), findsNothing);
      await tester.tap(find.byType(ComposerVideoPreview));
      await tester.pump();

      expect(player.calls, ['initialize', 'play', 'pause']);
      expect(find.byType(VideoPlayDisc), findsOneWidget);
    });

    testWidgets('× when she can still change it; leaving disposes the '
        'player', (tester) async {
      var removed = 0;
      await pump(tester, onRemove: () => removed++);

      await tester.tap(find.bySemanticsLabel('Remove video'));
      expect(removed, 1);

      await tester.pumpWidget(const SizedBox());
      expect(player.disposed, isTrue);
    });

    testWidgets('no × while it publishes', (tester) async {
      await pump(tester);

      expect(find.bySemanticsLabel('Remove video'), findsNothing);
    });
  });
}
