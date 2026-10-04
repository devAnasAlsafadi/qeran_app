import 'community_video_controller.dart';

/// One video plays at a time (Q9): the one that starts takes the turn, and
/// the one playing before it pauses.
class CommunityVideoCoordinator {
  CommunityVideoController? _active;

  void claim(CommunityVideoController controller) {
    if (identical(_active, controller)) return;
    _active?.suspend();
    _active = controller;
  }

  void release(CommunityVideoController controller) {
    if (identical(_active, controller)) _active = null;
  }

  bool holds(CommunityVideoController controller) =>
      identical(_active, controller);
}
