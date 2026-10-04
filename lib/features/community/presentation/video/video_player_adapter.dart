import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

import 'community_video_player.dart';

/// [CommunityVideoPlayer] over `video_player` — the app's player. The link
/// is requested without headers: no Bearer to the video's host (W5).
class VideoPlayerAdapter implements CommunityVideoPlayer {
  VideoPlayerAdapter(Uri url)
    : _controller = VideoPlayerController.networkUrl(url) {
    _controller.addListener(_sync);
  }

  final VideoPlayerController _controller;

  @override
  final ValueNotifier<CommunityPlayerValue> value = ValueNotifier(
    const CommunityPlayerValue(),
  );

  void _sync() {
    final v = _controller.value;
    final ended =
        v.isInitialized &&
        v.duration > Duration.zero &&
        !v.isPlaying &&
        v.position >= v.duration;
    value.value = CommunityPlayerValue(
      initialized: v.isInitialized,
      playing: v.isPlaying,
      buffering: v.isBuffering,
      completed: ended,
      failed: v.hasError,
      position: v.position,
      duration: v.duration,
    );
  }

  @override
  Future<void> initialize() => _controller.initialize();

  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> seekTo(Duration position) => _controller.seekTo(position);

  @override
  Future<void> setVolume(double volume) => _controller.setVolume(volume);

  @override
  Future<void> dispose() async {
    _controller.removeListener(_sync);
    await _controller.dispose();
    value.dispose();
  }

  @override
  Widget view() => VideoPlayer(_controller);
}
