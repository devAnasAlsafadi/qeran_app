import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

/// Where a player stands, as the card's controls read it.
class CommunityPlayerValue extends Equatable {
  const CommunityPlayerValue({
    this.initialized = false,
    this.playing = false,
    this.buffering = false,
    this.completed = false,
    this.failed = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  final bool initialized;
  final bool playing;
  final bool buffering;

  /// Played to the end.
  final bool completed;
  final bool failed;
  final Duration position;
  final Duration duration;

  @override
  List<Object?> get props => [
    initialized,
    playing,
    buffering,
    completed,
    failed,
    position,
    duration,
  ];
}

/// What the card needs from a video player: the app's is `video_player`
/// (`VideoPlayerAdapter`), and tests use a fake one — no network, no
/// platform view (Q1).
abstract class CommunityVideoPlayer {
  ValueNotifier<CommunityPlayerValue> get value;

  Future<void> initialize();
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);

  /// 0 mutes; 1 is full.
  Future<void> setVolume(double volume);
  Future<void> dispose();

  /// The picture, sized by its parent.
  Widget view();
}

/// Makes a player for a video's signed link. A plain request: the link is
/// signed, and our token never goes to the video's host (W5).
typedef CommunityVideoPlayerFactory = CommunityVideoPlayer Function(Uri url);

/// Makes a player for a file on the phone: her video in the composer, before
/// anything is sent (BA-D).
typedef CommunityLocalVideoPlayerFactory =
    CommunityVideoPlayer Function(String path);
