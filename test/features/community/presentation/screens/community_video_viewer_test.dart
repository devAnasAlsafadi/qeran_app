import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/community/presentation/screens/community_video_viewer.dart';
import 'package:qeran/features/community/presentation/widgets/post_card/post_video_tile.dart';
import 'package:qeran/features/community/presentation/widgets/video/video_layers.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../fixtures/community_post_fixtures.dart';
import '../widgets/video/video_rig.dart';

/// A card's video full screen (G4–G7, BA-E, S20, S22, Q9): the same player,
/// at its true ratio, rotated on request, handed back on close.
void main() {
  final orientations = <Object?>[];

  setUpAll(initShippedStrings);
  setUp(() {
    useFakePlayers();
    orientations.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'SystemChrome.setPreferredOrientations') {
            orientations.add(call.arguments);
          }
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    return sl.reset();
  });

  final theVideo = find.byKey(const ValueKey('the-video'));

  /// A playing card, then its full-screen button.
  Future<void> fullScreen(
    WidgetTester tester, {
    int w = 1080,
    int h = 1920,
  }) async {
    await pumpTiles(tester, [testVideo(width: w, height: h)]);
    await tester.tap(find.byType(VideoPlayDisc));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.fullscreen_rounded));
    await tester.pumpAndSettle();
  }

  testWidgets('S20: the same player, not a new one, its place kept; the card '
      'keeps its poster meanwhile, and gets it back', (tester) async {
    await fullScreen(tester);

    expect(find.byType(CommunityVideoViewer), findsOneWidget);
    expect(players, hasLength(1));
    expect(players.single.calls, ['initialize', 'play']);
    expect(theVideo, findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(CommunityVideoViewer), findsNothing);
    expect(
      find.descendant(of: find.byType(PostVideoTile), matching: theVideo),
      findsOneWidget,
    );
    expect(players.single.calls.contains('pause'), isFalse);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('G4, G5: the disc pauses and plays it', (tester) async {
    await fullScreen(tester);

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    expect(players.single.calls.last, 'pause');

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    expect(players.single.calls.last, 'play');
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Q9: rotate turns it landscape; closing gives the phone back', (
    tester,
  ) async {
    await fullScreen(tester);

    await tester.tap(find.byIcon(Icons.screen_rotation_rounded));
    await tester.pump();
    expect(orientations.last, [
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight',
    ]);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(orientations.last, <String>[]);
  });

  for (final (w, h) in [(1080, 1920), (1080, 1080), (1920, 1080)]) {
    testWidgets('BA-E: $w × $h at its true ratio, full width, centred', (
      tester,
    ) async {
      await fullScreen(tester, w: w, h: h);

      final box = tester.getRect(
        find.descendant(
          of: find.byType(CommunityVideoViewer),
          matching: find.byType(AspectRatio),
        ),
      );
      expect(box.width, 390);
      expect(box.height, closeTo(390 * h / w, 0.01));
      expect(box.center.dy, closeTo(2400 / 2, 0.5));
      await tester.pump(const Duration(seconds: 3));
    });
  }

  testWidgets('S22: too tall for the screen — contained inside it', (
    tester,
  ) async {
    await fullScreen(tester);
    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpAndSettle();

    final box = tester.getRect(
      find.descendant(
        of: find.byType(CommunityVideoViewer),
        matching: find.byType(AspectRatio),
      ),
    );
    expect(box.height, 390);
    expect(box.width, closeTo(390 * 1080 / 1920, 0.01));
  });

  testWidgets('G7: a failure full screen, with its retry', (tester) async {
    await fullScreen(tester);

    players.single.fail();
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(CommunityVideoViewer),
        matching: find.byType(VideoFailed),
      ),
      findsOneWidget,
    );
  });
}
