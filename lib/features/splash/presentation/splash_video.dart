import 'dart:async';

import 'package:video_player/video_player.dart';

import 'splash_reveal_policy.dart';

/// Builds the player for [asset]. Swapped in tests, which have no platform to
/// decode video on.
typedef SplashVideoFactory = VideoPlayerController Function(String asset);

VideoPlayerController _assetPlayer(String asset) =>
    VideoPlayerController.asset(asset);

/// Owns the splash animation's playback: load it, mute it, play it, and say
/// exactly once when it is over.
///
/// Lifted out of the widget so the part that can go wrong is the part that can
/// be tested. `video_player` needs a platform and cannot be driven in a widget
/// test, so a controller built inside `State` would leave every failure path
/// here — a load that throws, an error the player reports after a successful
/// load, an end that never arrives — provable only on a device.
///
/// ⚠️ [onSettled] fires at most ONCE, whatever happens. The splash treats it as
/// "the animation half is done" and three other things can also settle that
/// half (a tap, the backstop, dispose), so a second call could push a second
/// route onto the stack.
class SplashVideo {
  SplashVideo({
    required this.asset,
    required this.onSettled,
    SplashRevealPolicy policy = const SplashRevealPolicy(),
    SplashVideoFactory createController = _assetPlayer,
    void Function(String message, Object? error, StackTrace? stack)? onError,
  }) : _policy = policy,
       _create = createController,
       _onError = onError;

  final String asset;

  /// Called once when the animation is done for any reason this class can see:
  /// playback reached the end, the load threw, or the player reported an error.
  final VoidCallback onSettled;

  final SplashRevealPolicy _policy;
  final SplashVideoFactory _create;
  final void Function(String message, Object? error, StackTrace? stack)?
  _onError;

  VideoPlayerController? _controller;
  bool _settled = false;
  bool _disposed = false;

  /// The player once it has a first frame to show, or `null` while there is
  /// nothing to paint. The splash keeps its wine canvas until this is non-null,
  /// so no black frame is ever visible.
  VideoPlayerController? get controller => _ready ? _controller : null;
  bool _ready = false;

  /// Load, mute and play. Never throws: a failure settles instead, so a broken
  /// asset degrades to "route as soon as the decision is ready" rather than
  /// leaving the splash up forever.
  Future<void> start() async {
    final video = _create(asset);
    _controller = video;
    try {
      await video.initialize();
      // Belt-and-braces. The shipped asset carries no audio stream at all,
      // which is the guarantee that actually holds on iOS — muting a track
      // that exists still engages the playback audio category, and that
      // category ignores the ring/silent switch.
      await video.setVolume(0);
      if (_disposed) return;
      video.addListener(_onTick);
      _ready = true;
      // A player that finished before the listener was attached would never
      // report it, so the current value is checked once on the way in.
      _onTick();
      await video.play();
    } catch (error, stack) {
      _onError?.call('Splash video failed to load/play', error, stack);
      _settle();
    }
  }

  void _onTick() {
    final video = _controller;
    if (video == null || _settled) return;
    final value = video.value;
    if (value.hasError) {
      _onError?.call(
        'Splash video reported an error: ${value.errorDescription}',
        null,
        null,
      );
      _settle();
      return;
    }
    if (_policy.hasReachedEnd(
      position: value.position,
      total: value.duration,
    )) {
      _settle();
    }
  }

  void _settle() {
    if (_settled) return;
    _settled = true;
    onSettled();
  }

  /// Releases the player. Safe to call before or after [start], and safe to
  /// call twice.
  Future<void> dispose() async {
    _disposed = true;
    final video = _controller;
    _controller = null;
    _ready = false;
    if (video == null) return;
    video.removeListener(_onTick);
    await video.dispose();
  }
}

/// Kept local so this file needs nothing from the widget layer.
typedef VoidCallback = void Function();
