import 'package:flutter/widgets.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/server_clock.dart';
import '../../domain/entities/community_media.dart';
import 'community_video_controller.dart';
import 'community_video_coordinator.dart';
import 'community_video_player.dart';
import 'video_player_adapter.dart';

/// What the videos on one screen share.
class CommunityVideoScopeData {
  const CommunityVideoScopeData({
    required this.coordinator,
    required this.makePlayer,
    required this.freshVideo,
  });

  final CommunityVideoCoordinator coordinator;
  final CommunityVideoPlayerFactory makePlayer;
  final CommunityFreshVideo freshVideo;

  /// A controller for [video] of [postId], on this screen's turn-taking.
  CommunityVideoController controllerFor(int postId, CommunityVideo video) =>
      CommunityVideoController(
        postId: postId,
        video: video,
        makePlayer: makePlayer,
        coordinator: coordinator,
        now: ServerClock.instance.now,
        freshVideo: freshVideo,
      );
}

/// Above a screen's videos — the feed's, the post screen's: one coordinator,
/// so one video plays at a time (Q9); the app's player (`video_player`, or
/// the one DI holds for tests); and how a lapsed link is read again, through
/// the screen's cubit ([freshVideo], S19).
class CommunityVideoScope extends StatefulWidget {
  const CommunityVideoScope({
    super.key,
    required this.freshVideo,
    required this.child,
  });

  final CommunityFreshVideo freshVideo;
  final Widget child;

  static CommunityVideoScopeData? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_Scope>()?.data;

  @override
  State<CommunityVideoScope> createState() => _CommunityVideoScopeState();
}

class _CommunityVideoScopeState extends State<CommunityVideoScope> {
  final _coordinator = CommunityVideoCoordinator();

  static CommunityVideoPlayerFactory get _makePlayer =>
      sl.isRegistered<CommunityVideoPlayerFactory>()
      ? sl<CommunityVideoPlayerFactory>()
      : VideoPlayerAdapter.new;

  @override
  Widget build(BuildContext context) => _Scope(
    data: CommunityVideoScopeData(
      coordinator: _coordinator,
      makePlayer: _makePlayer,
      freshVideo: widget.freshVideo,
    ),
    child: widget.child,
  );
}

class _Scope extends InheritedWidget {
  const _Scope({required this.data, required super.child});

  final CommunityVideoScopeData data;

  @override
  bool updateShouldNotify(_Scope oldWidget) => false;
}
