import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../formatting/video_duration.dart';
import '../../video/community_video_controller.dart';
import '../video/video_icon_button.dart';
import '../video/video_timeline.dart';

/// The full-screen video's controls along the bottom (G4, G5): the
/// timeline, the time either side, then mute and rotate — left to right in
/// every language, as a player is.
class ViewerVideoPanel extends StatelessWidget {
  const ViewerVideoPanel({
    super.key,
    required this.controller,
    required this.onRotate,
  });

  final CommunityVideoController controller;
  final VoidCallback onRotate;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 44, child: VideoTimeline(controller: c, thumb: 7)),
          Row(
            textDirection: TextDirection.ltr,
            children: [_time(c.position), const Spacer(), _time(c.duration)],
          ),
          QeranSpacing.vs4,
          _buttons(),
        ],
      ),
    );
  }

  /// Mute at the left, rotate at the right.
  Widget _buttons() => Row(
    textDirection: TextDirection.ltr,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      VideoIconButton(
        icon: controller.muted
            ? Icons.volume_off_rounded
            : Icons.volume_up_rounded,
        size: 24,
        label: controller.muted
            ? LocaleKeys.community_video_unmute
            : LocaleKeys.community_video_mute,
        onTap: controller.toggleMute,
      ),
      VideoIconButton(
        icon: Icons.screen_rotation_rounded,
        size: 24,
        label: LocaleKeys.community_video_rotate,
        onTap: onRotate,
      ),
    ],
  );

  static Widget _time(Duration at) => Text(
    formatVideoDuration(at),
    textDirection: TextDirection.ltr,
    style: QeranTypography.numeric.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: QeranColors.paper,
    ),
  );
}
