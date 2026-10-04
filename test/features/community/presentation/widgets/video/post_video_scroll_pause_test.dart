import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/community/presentation/video/community_video_scope.dart';
import 'package:qeran/features/community/presentation/widgets/post_card/post_video_tile.dart';

import '../../../../../core/shipped_strings_rig.dart';
import '../../../../auth/presentation/fake_session.dart';
import '../../../fixtures/community_post_fixtures.dart';
import 'video_rig.dart';

/// Scrolled mostly out of view, a playing video pauses — no sound from a
/// video the member can't see (Anas, 2026-10-04) — and nothing plays again
/// when it comes back.
void main() {
  setUpAll(initShippedStrings);
  setUp(useFakePlayers);
  tearDown(sl.reset);

  // The tile: 100 pt down a list in an 800 pt screen, 417.5 pt tall (a
  // vertical video at 4:5, 334 pt wide).
  const top = 100.0;
  const height = 417.5;
  late ScrollController list;

  Future<void> pumpList(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 800);
    addTearDown(tester.view.reset);
    list = ScrollController();
    addTearDown(list.dispose);
    return pumpShippedStrings(
      tester,
      const Locale('en'),
      child: withSession(
        CommunityVideoScope(
          freshVideo: (_) async => null,
          child: ListView(
            controller: list,
            children: [
              const SizedBox(height: top),
              SizedBox(
                width: 358,
                child: PostVideoTile(postId: 1, video: testVideo()),
              ),
              const SizedBox(height: 2000),
            ],
          ),
        ),
      ),
    );
  }

  /// Scrolled so that [share] of the tile is still on screen.
  Future<void> scrollToShare(WidgetTester tester, double share) async {
    list.jumpTo(top + height * (1 - share));
    await tester.pump();
  }

  Future<void> play(WidgetTester tester) async {
    await tester.tap(playDisc());
    await tester.pump();
    expect(players.single.calls.last, 'play');
  }

  testWidgets('more than half in view: it plays on', (tester) async {
    await pumpList(tester);
    await play(tester);

    await scrollToShare(tester, 0.6);

    expect(players.single.calls.last, 'play');
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('under half in view: it pauses, and scrolling back doesn\'t '
      'play it again', (tester) async {
    await pumpList(tester);
    await play(tester);

    await scrollToShare(tester, 0.4);
    expect(players.single.calls.last, 'pause');

    await scrollToShare(tester, 1);
    expect(players.single.calls.where((c) => c == 'play'), hasLength(1));
    expect(players.single.value.value.playing, isFalse);
  });

  testWidgets('one that isn\'t playing is left alone', (tester) async {
    await pumpList(tester);

    await scrollToShare(tester, 0.2);

    expect(players, isEmpty);
  });
}
