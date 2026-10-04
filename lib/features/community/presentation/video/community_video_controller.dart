import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/community_media.dart';
import 'community_video_coordinator.dart';
import 'community_video_phase.dart';
import 'community_video_player.dart';

/// A fresh copy of a post's video, read again when its signed link has
/// lapsed (S19, W5); null when it couldn't be read.
typedef CommunityFreshVideo = Future<CommunityVideo?> Function(int postId);

/// One card's playback (A9–A14): the player made on the first tap, its
/// phase, the controls that fade while it plays, mute and seek. A lapsed
/// link is read again before playing. UI logic only — the screen's cubits
/// never hear about playback.
class CommunityVideoController extends ChangeNotifier {
  CommunityVideoController({
    required this.postId,
    required CommunityVideo video,
    required CommunityVideoPlayerFactory makePlayer,
    required CommunityVideoCoordinator coordinator,
    required DateTime Function() now,
    CommunityFreshVideo? freshVideo,
    this.controlsFor = const Duration(seconds: 3),
  }) : _video = video,
       _makePlayer = makePlayer,
       _coordinator = coordinator,
       _now = now,
       _freshVideo = freshVideo;

  final int postId;

  /// How long the controls stay while it plays, untouched.
  final Duration controlsFor;
  final CommunityVideoPlayerFactory _makePlayer;
  final CommunityVideoCoordinator _coordinator;
  final DateTime Function() _now;
  final CommunityFreshVideo? _freshVideo;

  CommunityVideo _video;
  CommunityVideoPlayer? _player;
  bool _starting = false;
  bool _failed = false;
  bool _controlsShown = true;
  bool _muted = false;
  Timer? _fade;

  CommunityVideoPlayer? get player => _player;
  bool get muted => _muted;
  CommunityPlayerValue get _value =>
      _player?.value.value ?? const CommunityPlayerValue();

  CommunityVideoPhase get phase => videoPhaseOf(
    _value,
    started: _player != null,
    starting: _starting,
    failed: _failed,
  );

  Duration get position => _value.position;
  Duration get duration =>
      _value.duration > Duration.zero ? _value.duration : _video.duration;

  /// The bar shows while paused, and while playing until it fades.
  bool get controlsShown =>
      phase == CommunityVideoPhase.paused ||
      (phase == CommunityVideoPhase.playing && _controlsShown);

  /// The card got a newer copy of the post: its links, for the next start.
  set video(CommunityVideo video) => _video = video;

  Future<void> play() async {
    _coordinator.claim(this);
    final player = _player;
    if (player == null) return _start();
    if (phase == CommunityVideoPhase.ended) await player.seekTo(Duration.zero);
    await player.play();
    _showControls();
  }

  void pause() {
    unawaited(_player?.pause());
    _showControls();
  }

  void togglePlay() =>
      phase == CommunityVideoPhase.playing ? pause() : unawaited(play());

  /// After a failure (A14): a new player, its link read again if lapsed.
  Future<void> retry() async {
    await _drop();
    _failed = false;
    await play();
  }

  void toggleMute() {
    _muted = !_muted;
    unawaited(_player?.setVolume(_muted ? 0 : 1));
    _showControls();
  }

  /// Seeks to [fraction] (0–1) of the length.
  void seekTo(double fraction) {
    unawaited(_player?.seekTo(duration * fraction.clamp(0, 1)));
    _showControls();
  }

  /// A tap on the playing picture brings the bar back, or sends it away.
  void tapPicture() {
    if (phase != CommunityVideoPhase.playing) return;
    if (!_controlsShown) return _showControls();
    _fade?.cancel();
    _controlsShown = false;
    notifyListeners();
  }

  /// Paused from outside — another video, a hidden tab, a covering route,
  /// the app in the background (Q9).
  void suspend() {
    if (phase == CommunityVideoPhase.playing ||
        phase == CommunityVideoPhase.buffering) {
      unawaited(_player?.pause());
    }
  }

  Future<void> _start() async {
    _starting = true;
    notifyListeners();
    final url = (await _currentVideo())?.url;
    if (url == null || url.trim().isEmpty) return _fail();
    final player = _makePlayer(Uri.parse(url));
    _player = player..value.addListener(notifyListeners);
    try {
      await player.initialize();
      await player.setVolume(_muted ? 0 : 1);
      _starting = false;
      // Another video may have taken the turn while this one loaded.
      if (_coordinator.holds(this)) await player.play();
      _showControls();
    } catch (_) {
      _fail();
    }
  }

  /// The video to play: read again first when its link has lapsed.
  Future<CommunityVideo?> _currentVideo() async {
    final expires = _video.urlExpiresAt;
    if (expires == null || _now().isBefore(expires)) return _video;
    final fresh = await _freshVideo?.call(postId);
    if (fresh == null) return null;
    return _video = fresh;
  }

  void _fail() {
    _starting = false;
    _failed = true;
    notifyListeners();
  }

  void _showControls() {
    _controlsShown = true;
    _fade?.cancel();
    _fade = Timer(controlsFor, () {
      _controlsShown = false;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> _drop() async {
    final player = _player;
    _player = null;
    player?.value.removeListener(notifyListeners);
    await player?.dispose();
  }

  @override
  void dispose() {
    _fade?.cancel();
    _coordinator.release(this);
    unawaited(_drop());
    super.dispose();
  }
}
