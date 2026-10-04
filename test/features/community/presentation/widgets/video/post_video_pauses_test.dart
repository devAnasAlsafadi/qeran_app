import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/community/presentation/widgets/post_card/post_video_tile.dart';
import 'package:qeran/features/community/presentation/widgets/video/video_controls_bar.dart';
import 'package:qeran/features/community/presentation/widgets/video/video_layers.dart';

import '../../../../../core/shipped_strings_rig.dart';
import '../../../fixtures/community_post_fixtures.dart';
import 'video_rig.dart';

/// Q9: one video at a time, and it pauses when its tab is hidden, a route
/// covers it, or the app leaves the foreground. S19: a lapsed link is read
/// again first. BA-B4: the controls span the frame.
void main() {
  setUpAll(initShippedStrings);
  setUp(useFakePlayers);
  tearDown(sl.reset);

  /// Taps the play disc of the [index]th tile.
  Future<void> start(WidgetTester tester, [int index = 0]) async {
    await tester.tap(
      find.descendant(
        of: find.byType(PostVideoTile).at(index),
        matching: find.byType(VideoPlayDisc),
      ),
    );
    await tester.pump();
  }

  Future<void> settleControls(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 3));

  testWidgets('one at a time: the next one pauses the first', (tester) async {
    await pumpTiles(tester, [testVideo(), testVideo()]);
    await start(tester);

    await start(tester, 1);

    expect(players.first.calls.last, 'pause');
    expect(players.last.calls.last, 'play');
    await settleControls(tester);
  });

  testWidgets('a hidden tab pauses it', (tester) async {
    final shown = ValueNotifier(true);
    await pumpTiles(tester, [testVideo()], shown: shown);
    await start(tester);

    shown.value = false;
    await tester.pump();

    expect(players.single.calls.last, 'pause');
    await settleControls(tester);
  });

  testWidgets('a route over it pauses it', (tester) async {
    await pumpTiles(tester, [testVideo()]);
    await start(tester);

    Navigator.of(
      tester.element(find.byType(PostVideoTile)),
    ).push(MaterialPageRoute<void>(builder: (_) => const Scaffold()));
    await tester.pumpAndSettle();

    expect(players.single.calls.last, 'pause');
  });

  testWidgets('a sheet over it (the ⋮ menu) pauses it too', (tester) async {
    await pumpTiles(tester, [testVideo()]);
    await start(tester);

    showModalBottomSheet<void>(
      context: tester.element(find.byType(PostVideoTile)),
      builder: (_) => const SizedBox(height: 120),
    );
    await tester.pumpAndSettle();

    expect(players.single.calls.last, 'pause');
  });

  for (final (platform, state, pauses) in [
    (TargetPlatform.android, AppLifecycleState.hidden, true),
    (TargetPlatform.android, AppLifecycleState.paused, true),
    (TargetPlatform.android, AppLifecycleState.inactive, false),
    (TargetPlatform.iOS, AppLifecycleState.inactive, true),
  ]) {
    testWidgets('${platform.name}, $state: ${pauses ? '' : 'not '}paused '
        '(D12)', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await pumpTiles(tester, [testVideo()]);
      await start(tester);

      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();

      expect(players.single.calls.contains('pause'), pauses);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settleControls(tester);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('S19: a lapsed link is read again before it plays', (
    tester,
  ) async {
    const freshLink = 'https://vz-abc.b-cdn.net/v-1/play_720p.mp4?token=new';
    final asked = <int>[];
    await pumpTiles(
      tester,
      [testVideo(urlExpiresAt: DateTime.utc(2000))],
      fresh: (postId) async {
        asked.add(postId);
        return testVideo(url: freshLink, urlExpiresAt: DateTime.utc(2100));
      },
    );

    await start(tester);
    await tester.pump();

    expect(asked, [1]);
    expect(players.single.url.toString(), freshLink);
    await settleControls(tester);
  });

  testWidgets("S19: a lapsed link that can't be read again fails, with its "
      'retry', (tester) async {
    await pumpTiles(tester, [testVideo(urlExpiresAt: DateTime.utc(2000))]);

    await start(tester);
    await tester.pump();

    expect(players, isEmpty);
    expect(find.byType(VideoFailed), findsOneWidget);
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('BA-B4: at 9:16 the controls span the frame, play at the '
        'left [${locale.languageCode}]', (tester) async {
      await pumpTiles(tester, [testVideo()], locale: locale);
      await start(tester);

      final frame = tester.getRect(find.byType(AspectRatio).first);
      final bar = tester.getRect(find.byType(VideoControlsBar));
      final pause = tester.getCenter(find.byIcon(Icons.pause_rounded));

      expect(frame.width / frame.height, closeTo(0.8, 0.01));
      expect(bar.left, frame.left);
      expect(bar.width, frame.width);
      expect(bar.bottom, frame.bottom);
      expect(pause.dx, lessThan(frame.center.dx));
      await settleControls(tester);
    });
  }
}
