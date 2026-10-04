import 'community_video_player.dart';

/// What a card's video shows (A9–A14).
enum CommunityVideoPhase {
  /// The poster, the play disc and the length (A9).
  idle,

  /// Starting, its link being read again, or waiting for data (A10).
  buffering,

  /// The controls, fading after a while (A11).
  playing,

  /// The play disc and the controls (A12).
  paused,

  /// Dimmed, with the replay disc (A13).
  ended,

  /// Dimmed, the failure and its retry (A14).
  error,
}

/// The phase a player's [value] makes: [started] once a player exists,
/// [starting] while it loads, [failed] when it couldn't.
CommunityVideoPhase videoPhaseOf(
  CommunityPlayerValue value, {
  required bool started,
  required bool starting,
  required bool failed,
}) {
  if (failed || value.failed) return CommunityVideoPhase.error;
  if (starting) return CommunityVideoPhase.buffering;
  if (!started) return CommunityVideoPhase.idle;
  if (!value.initialized) return CommunityVideoPhase.buffering;
  if (value.completed) return CommunityVideoPhase.ended;
  if (!value.playing) return CommunityVideoPhase.paused;
  return value.buffering
      ? CommunityVideoPhase.buffering
      : CommunityVideoPhase.playing;
}
