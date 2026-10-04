import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/presentation/video/community_video_phase.dart';
import 'package:qeran/features/community/presentation/video/community_video_player.dart';

/// A9–A14 from a player's state.
void main() {
  CommunityVideoPhase phaseOf(
    CommunityPlayerValue value, {
    bool started = true,
    bool starting = false,
    bool failed = false,
  }) =>
      videoPhaseOf(value, started: started, starting: starting, failed: failed);

  const ready = CommunityPlayerValue(initialized: true);

  test('no player yet: the poster', () {
    expect(
      phaseOf(const CommunityPlayerValue(), started: false),
      CommunityVideoPhase.idle,
    );
  });

  test('loading, or waiting for data while playing: buffering', () {
    expect(
      phaseOf(const CommunityPlayerValue(), starting: true),
      CommunityVideoPhase.buffering,
    );
    expect(
      phaseOf(const CommunityPlayerValue()),
      CommunityVideoPhase.buffering,
    );
    expect(
      phaseOf(
        const CommunityPlayerValue(
          initialized: true,
          playing: true,
          buffering: true,
        ),
      ),
      CommunityVideoPhase.buffering,
    );
  });

  test('playing, paused, ended', () {
    expect(
      phaseOf(const CommunityPlayerValue(initialized: true, playing: true)),
      CommunityVideoPhase.playing,
    );
    expect(phaseOf(ready), CommunityVideoPhase.paused);
    expect(
      phaseOf(const CommunityPlayerValue(initialized: true, completed: true)),
      CommunityVideoPhase.ended,
    );
  });

  test('a failure wins over everything', () {
    expect(phaseOf(ready, failed: true), CommunityVideoPhase.error);
    expect(
      phaseOf(const CommunityPlayerValue(initialized: true, failed: true)),
      CommunityVideoPhase.error,
    );
  });
}
