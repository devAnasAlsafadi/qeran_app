import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../formatting/video_duration.dart';
import '../../video/community_video_controller.dart';
import '../../video/community_video_phase.dart';

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
          Expanded(child: _Timeline(controller: controller)),
          _time(),
          _mute(),
          if (onFullScreen case final open?)
            _IconButton(
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
    return _IconButton(
      icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
      size: 26,
      label: playing
          ? LocaleKeys.community_video_pause
          : LocaleKeys.community_video_play,
      onTap: controller.togglePlay,
    );
  }

  Widget _mute() => _IconButton(
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

/// The played part in gold over a gold-40 track, with its thumb; a tap or a
/// drag seeks.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.controller});

  final CommunityVideoController controller;

  double get _played {
    final total = controller.duration.inMilliseconds;
    if (total <= 0) return 0;
    return (controller.position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: LocaleKeys.community_video_seek.t(context),
      child: LayoutBuilder(
        builder: (context, box) {
          void seek(Offset at) => controller.seekTo(at.dx / box.maxWidth);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => seek(d.localPosition),
            onHorizontalDragUpdate: (d) => seek(d.localPosition),
            child: SizedBox(
              height: 44,
              child: CustomPaint(painter: _TimelinePainter(_played)),
            ),
          );
        },
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  const _TimelinePainter(this.played);

  final double played;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final track = RRect.fromLTRBR(
      0,
      y - 2,
      size.width,
      y + 2,
      const Radius.circular(2),
    );
    canvas.drawRRect(track, Paint()..color = QeranColors.gold40);
    final x = size.width * played;
    canvas.drawRRect(
      RRect.fromLTRBR(0, y - 2, x, y + 2, const Radius.circular(2)),
      Paint()..color = QeranColors.gold,
    );
    canvas.drawCircle(Offset(x, y), 6, Paint()..color = QeranColors.gold);
  }

  @override
  bool shouldRepaint(_TimelinePainter old) => old.played != played;
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.size,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label.t(context),
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: SizedBox.square(
          dimension: 44,
          child: Icon(icon, size: size, color: QeranColors.paper),
        ),
      ),
    );
  }
}
