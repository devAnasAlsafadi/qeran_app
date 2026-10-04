import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../formatting/video_duration.dart';
import '../../video/community_video_controller.dart';
import '../../video/community_video_phase.dart';
import 'video_icon_button.dart';
import 'video_timeline.dart';

/// The bar along the frame's bottom while it plays or is paused (A11, A12,
/// BA-B4): play/pause, the timeline, the time, mute, and full screen when
/// [onFullScreen] is given. Left to right in every language, as a player
/// is (the row's own direction, not the page's), and as wide as the frame —
/// over the wine bars of a vertical video.
class VideoControlsBar extends StatelessWidget {
  const VideoControlsBar({
    super.key,
    required this.controller,
    this.onFullScreen,
  });

  final CommunityVideoController controller;
  final VoidCallback? onFullScreen;

  static const double height = 48;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          _playPause(),
          Expanded(child: VideoTimeline(controller: controller)),
          _time(),
          _mute(),
          if (onFullScreen case final open?)
            VideoIconButton(
              icon: Icons.fullscreen_rounded,
              size: 24,
              label: LocaleKeys.community_video_full_screen,
              onTap: open,
            ),
        ],
      ),
    );
  }

  Widget _playPause() {
    final playing = controller.phase == CommunityVideoPhase.playing;
    return VideoIconButton(
      icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
      size: 26,
      label: playing
          ? LocaleKeys.community_video_pause
          : LocaleKeys.community_video_play,
      onTap: controller.togglePlay,
    );
  }

  Widget _mute() => VideoIconButton(
    icon: controller.muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
    size: 22,
    label: controller.muted
        ? LocaleKeys.community_video_unmute
        : LocaleKeys.community_video_mute,
    onTap: controller.toggleMute,
  );

  Widget _time() => Padding(
    padding: const EdgeInsets.fromLTRB(10, 0, 6, 0),
    child: Text(
      '${formatVideoDuration(controller.position)} / '
      '${formatVideoDuration(controller.duration)}',
      textDirection: TextDirection.ltr,
      style: QeranTypography.numeric.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: QeranColors.paper,
      ),
    ),
  );
}
