import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/community/domain/entities/community_media.dart';
import 'package:qeran/features/community/presentation/video/community_video_player.dart';
import 'package:qeran/features/community/presentation/video/community_video_scope.dart';
import 'package:qeran/features/community/presentation/widgets/post_card/post_video_tile.dart';

import '../../../../../core/shipped_strings_rig.dart';
import '../../../../auth/presentation/fake_session.dart';

/// A player with no network and no platform view (Q1): it does what it's
/// told, and a test moves it on — [finish], [fail], [buffer].
class FakePlayer implements CommunityVideoPlayer {
  FakePlayer(this.url);

  final Uri url;
  final calls = <String>[];
  double volume = 1;
  bool disposed = false;

  /// Holds [initialize] until completed, to see the loading disc.
  Completer<void>? initGate;
  bool failToStart = false;

  static const length = Duration(seconds: 52);

  @override
  final value = ValueNotifier(const CommunityPlayerValue());

  void _set({bool? playing, bool? completed, bool? failed, Duration? at}) {
    final v = value.value;
    value.value = CommunityPlayerValue(
      initialized: true,
      playing: playing ?? v.playing,
      completed: completed ?? v.completed,
      failed: failed ?? v.failed,
      position: at ?? v.position,
      duration: length,
    );
  }

  void finish() => _set(playing: false, completed: true, at: length);
  void fail() => _set(failed: true);

  @override
  Future<void> initialize() async {
    calls.add('initialize');
    await initGate?.future;
    if (failToStart) throw Exception('no video');
    _set();
  }

  @override
  Future<void> play() async {
    calls.add('play');
    _set(playing: true, completed: false);
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    _set(playing: false);
  }

  @override
  Future<void> seekTo(Duration position) async {
    calls.add('seek ${position.inSeconds}');
    _set(at: position);
  }

  @override
  Future<void> setVolume(double volume) async => this.volume = volume;

  @override
  Future<void> dispose() async => disposed = true;

  @override
  Widget view() => const SizedBox.expand(key: ValueKey('the-video'));
}

/// Every player the tiles made, in order.
final players = <FakePlayer>[];

/// The app's player swapped for [FakePlayer] (as DI holds it).
void useFakePlayers({void Function(FakePlayer player)? setUp}) {
  players.clear();
  if (sl.isRegistered<CommunityVideoPlayerFactory>()) {
    sl.unregister<CommunityVideoPlayerFactory>();
  }
  sl.registerSingleton<CommunityVideoPlayerFactory>((url) {
    final player = FakePlayer(url);
    setUp?.call(player);
    players.add(player);
    return player;
  });
}

/// [videos] as tiles of posts 1, 2… in one screen's scope, in [locale];
/// a lapsed link is read again through [fresh]. [shown] stands for the
/// tab: false is a hidden one.
Future<void> pumpTiles(
  WidgetTester tester,
  List<CommunityVideo> videos, {
  Locale locale = const Locale('en'),
  Future<CommunityVideo?> Function(int postId)? fresh,
  ValueNotifier<bool>? shown,
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 2400);
  addTearDown(tester.view.reset);
  return pumpShippedStrings(
    tester,
    locale,
    child: withSession(
      ValueListenableBuilder<bool>(
        valueListenable: shown ?? ValueNotifier(true),
        builder: (_, enabled, child) =>
            TickerMode(enabled: enabled, child: child!),
        child: CommunityVideoScope(
          freshVideo: fresh ?? (_) async => null,
          child: ListView(
            children: [
              for (final (i, video) in videos.indexed)
                SizedBox(
                  width: 358,
                  child: PostVideoTile(postId: i + 1, video: video),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The [index]th tile's play disc.
Finder playDisc([int index = 0]) =>
    find.byIcon(Icons.play_arrow_rounded).at(index);
