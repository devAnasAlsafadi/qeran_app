import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/splash/presentation/splash_video.dart';
import 'package:video_player/video_player.dart';

/// The reason [SplashVideo] exists as its own unit: `video_player` needs a
/// platform to decode on, so none of these paths — a load that throws, an error
/// the player reports after loading, an end that never arrives — could be
/// proven anywhere but a device while this logic lived inside `State`.

/// Stands in for a real player. Extends the same [ValueNotifier] the real
/// controller does, so `addListener` / `value` are genuine rather than stubbed,
/// and a test can push a new value and watch the listener fire for real.
class _FakePlayer extends ValueNotifier<VideoPlayerValue>
    implements VideoPlayerController {
  _FakePlayer({
    this.throwOnInitialize = false,
    this.throwOnPlay = false,
    Duration duration = const Duration(milliseconds: 4333),
    Duration positionAfterLoad = Duration.zero,
  }) : _duration = duration,
       _positionAfterLoad = positionAfterLoad,
       super(VideoPlayerValue(duration: duration));

  final bool throwOnInitialize;
  final bool throwOnPlay;
  final Duration _duration;

  /// Where playback sits the instant loading finishes. A very short asset can
  /// genuinely be complete by then.
  final Duration _positionAfterLoad;

  /// Whether anything is still listening — the observable half of `dispose`.
  bool get listenerAttached => hasListeners;

  bool initialized = false;
  bool played = false;
  bool disposed = false;

  /// Whether anything was still listening at the moment `dispose` was entered
  /// — sampled BEFORE `super.dispose()`, which clears listeners on its own and
  /// would otherwise mask whether the caller detached properly.
  bool? listenersOnEntry;
  final List<double> volumes = [];

  @override
  Future<void> initialize() async {
    if (throwOnInitialize) {
      throw Exception('no platform to decode on');
    }
    initialized = true;
    value = VideoPlayerValue(
      duration: _duration,
      position: _positionAfterLoad,
      isInitialized: true,
    );
  }

  @override
  Future<void> setVolume(double volume) async => volumes.add(volume);

  @override
  Future<void> play() async {
    if (throwOnPlay) {
      throw Exception('surface went away');
    }
    played = true;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    listenersOnEntry = hasListeners;
    super.dispose();
  }

  /// Drive playback the way the real player does — by publishing a new value.
  void tickTo(Duration position, {Duration? total}) {
    value = VideoPlayerValue(
      duration: total ?? _duration,
      position: position,
      isInitialized: true,
    );
  }

  void reportError(String description) {
    value = VideoPlayerValue(
      duration: _duration,
      errorDescription: description,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  late int settled;
  late List<String> errors;

  setUp(() {
    settled = 0;
    errors = [];
  });

  SplashVideo build(_FakePlayer player) => SplashVideo(
    asset: 'assets/animations/logo_qeran_v8_silent.mp4',
    onSettled: () => settled++,
    createController: (_) => player,
    onError: (message, error, stack) => errors.add(message),
  );

  group('starting up', () {
    test('loads, mutes, then plays — in that order', () async {
      final player = _FakePlayer();

      await build(player).start();

      expect(player.initialized, isTrue);
      expect(player.played, isTrue);
    });

    test('mutes to silence, not merely to quiet', () async {
      final player = _FakePlayer();

      await build(player).start();

      // Belt-and-braces over an asset that carries no audio track at all. A
      // non-zero value here would be audible the moment anyone swapped in a
      // file that did.
      expect(player.volumes, [0.0]);
    });

    test('paints nothing until there is a real frame', () async {
      final player = _FakePlayer();
      final video = build(player);

      // Before `start`, the splash must show bare wine rather than a black
      // rectangle where the player will be.
      expect(video.controller, isNull);

      await video.start();

      expect(video.controller, same(player));
    });

    test('does not settle merely because it started', () async {
      final player = _FakePlayer();

      await build(player).start();

      expect(settled, 0);
    });
  });

  group('reaching the end', () {
    test('settles when playback runs out', () async {
      final player = _FakePlayer();
      await build(player).start();

      player.tickTo(const Duration(milliseconds: 4333));

      expect(settled, 1);
    });

    test('does not settle part way through', () async {
      final player = _FakePlayer();
      await build(player).start();

      player.tickTo(const Duration(milliseconds: 2000));

      expect(settled, 0);
    });

    test('does not settle while the length is still unknown', () async {
      final player = _FakePlayer();
      await build(player).start();

      // Position and duration both zero is what a player reports before it
      // knows anything. Reading that as "finished" ends the splash on frame
      // one — the single-frame splash the dual gate exists to prevent.
      player.tickTo(Duration.zero, total: Duration.zero);

      expect(settled, 0);
    });

    test('settles once, however many ticks arrive after the end', () async {
      final player = _FakePlayer();
      await build(player).start();

      player.tickTo(const Duration(milliseconds: 4333));
      player.tickTo(const Duration(milliseconds: 4400));
      player.tickTo(const Duration(milliseconds: 4500));

      // A second settle would push a second route onto the stack.
      expect(settled, 1);
    });

    test('catches a player that finished before anyone was listening', () async {
      // Real players can complete during `initialize` on a very short asset;
      // the end would then never be announced to a listener attached after, so
      // the value is checked once on the way in.
      final player = _FakePlayer(
        positionAfterLoad: const Duration(milliseconds: 4333),
      );

      await build(player).start();

      expect(settled, 1);
    });
  });

  group('when it goes wrong', () {
    test('a load that throws settles instead of hanging the splash', () async {
      final player = _FakePlayer(throwOnInitialize: true);

      await build(player).start();

      expect(settled, 1);
      expect(errors, isNotEmpty);
    });

    test('a load that throws never leaves a frame to paint', () async {
      final player = _FakePlayer(throwOnInitialize: true);
      final video = build(player);

      await video.start();

      expect(video.controller, isNull);
    });

    test('an error reported after loading also settles', () async {
      final player = _FakePlayer();
      await build(player).start();

      player.reportError('decoder gave up');

      expect(settled, 1);
      expect(errors.single, contains('decoder gave up'));
    });

    test('a failure AFTER the end still only settles once', () async {
      // The one path that reaches `_settle` twice: a very short asset is
      // already complete when the listener attaches and settles on the way in,
      // then `play` throws and the catch settles again. The tick guard cannot
      // catch this one, because the second call does not come through a tick.
      final player = _FakePlayer(
        positionAfterLoad: const Duration(milliseconds: 4333),
        throwOnPlay: true,
      );

      await build(player).start();

      expect(settled, 1);
    });

    test('an error after the end does not settle a second time', () async {
      final player = _FakePlayer();
      await build(player).start();

      player.tickTo(const Duration(milliseconds: 4333));
      player.reportError('decoder gave up');

      expect(settled, 1);
    });
  });

  group('shutting down', () {
    test('releases the player', () async {
      final player = _FakePlayer();
      final video = build(player);
      await video.start();

      await video.dispose();

      expect(player.disposed, isTrue);
    });

    test('stops painting once disposed', () async {
      final player = _FakePlayer();
      final video = build(player);
      await video.start();

      await video.dispose();

      expect(video.controller, isNull);
    });

    test('a disposed player can no longer settle the splash', () async {
      final player = _FakePlayer();
      final video = build(player);
      await video.start();
      expect(player.listenerAttached, isTrue);

      await video.dispose();

      // Sampled on ENTRY to the player dispose, because `super.dispose()`
      // clears listeners by itself — checking afterwards would pass whether or
      // not we detached, which is exactly the false pass a mutation found here.
      expect(player.listenersOnEntry, isFalse);
      expect(player.listenerAttached, isFalse);
      expect(settled, 0);
    });

    test('disposing before it ever started is harmless', () async {
      final video = build(_FakePlayer());

      await video.dispose();

      expect(settled, 0);
    });

    test('disposing twice is harmless', () async {
      final player = _FakePlayer();
      final video = build(player);
      await video.start();

      await video.dispose();
      await video.dispose();

      expect(player.disposed, isTrue);
    });
  });
}
