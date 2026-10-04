import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/community/presentation/widgets/video/video_controls_bar.dart';
import 'package:qeran/features/community/presentation/widgets/video/video_layers.dart';

import '../../../../../core/shipped_strings_rig.dart';
import '../../../fixtures/community_post_fixtures.dart';
import 'video_rig.dart';

/// Playing a video in its card (A9–A14): tap, load, play, the controls that
/// fade, pause, the end, a failure and its retry.
void main() {
  setUpAll(initShippedStrings);
  setUp(useFakePlayers);
  tearDown(sl.reset);

  Finder disc() => find.byType(VideoPlayDisc);

  Future<void> start(WidgetTester tester) async {
    await tester.tap(disc());
    await tester.pump();
  }

  testWidgets('A9 → A10 → A11: the disc, the loader, then the video with '
      'its controls — from the signed link', (tester) async {
    useFakePlayers(setUp: (p) => p.initGate = Completer());
    await pumpTiles(tester, [testVideo()]);

    await start(tester);
    expect(find.byType(VideoBufferingDisc), findsOneWidget);
    expect(find.byType(VideoDim), findsOneWidget);

    players.single.initGate!.complete();
    await tester.pump();

    expect(players.single.url.toString(), signedVideo);
    expect(players.single.calls, ['initialize', 'play']);
    expect(find.byKey(const ValueKey('the-video')), findsOneWidget);
    expect(find.byType(VideoControlsBar), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(disc(), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('A11: the controls fade after 3 s, and a tap brings them back', (
    tester,
  ) async {
    await pumpTiles(tester, [testVideo()]);
    await start(tester);

    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(VideoControlsBar), findsNothing);

    await tester.tap(find.byKey(const ValueKey('the-video')));
    await tester.pump();
    expect(find.byType(VideoControlsBar), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('A12: paused — the disc and the controls, which stay', (
    tester,
  ) async {
    await pumpTiles(tester, [testVideo()]);
    await start(tester);

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump(const Duration(seconds: 5));

    expect(disc(), findsOneWidget);
    expect(find.byType(VideoControlsBar), findsOneWidget);
    expect(players.single.calls.last, 'pause');
  });

  testWidgets('A13: the end — dimmed, replay starts it over', (tester) async {
    await pumpTiles(tester, [testVideo()]);
    await start(tester);

    players.single.finish();
    await tester.pump();
    expect(find.byType(VideoDim), findsOneWidget);
    expect(find.byIcon(Icons.replay_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.replay_rounded));
    await tester.pump();
    expect(players.single.calls.sublist(2), ['seek 0', 'play']);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets("A14: it couldn't play — why, and a retry with a new player "
      '[ar]', (tester) async {
    useFakePlayers(setUp: (p) => p.failToStart = players.isEmpty);
    await pumpTiles(tester, [testVideo()], locale: const Locale('ar'));
    await start(tester);
    await tester.pump();

    expect(find.text('تعذّر تشغيل الفيديو'), findsOneWidget);
    await tester.tap(find.text('حاول مرة أخرى'));
    await tester.pump();
    await tester.pump();

    expect(players, hasLength(2));
    expect(players.first.disposed, isTrue);
    expect(players.last.calls, ['initialize', 'play']);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('mute, and the timeline seeks', (tester) async {
    await pumpTiles(tester, [testVideo()]);
    await start(tester);

    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    await tester.pump();
    expect(players.single.volume, 0);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

    final bar = tester.getRect(find.byType(VideoControlsBar));
    await tester.tapAt(Offset(bar.center.dx, bar.center.dy));
    await tester.pump();
    expect(players.single.calls.last, startsWith('seek '));
    await tester.pump(const Duration(seconds: 3));
  });
}
