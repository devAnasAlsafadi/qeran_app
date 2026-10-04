import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../video/community_video_controller.dart';

/// The played part in gold over a gold-40 track, with its thumb; a tap or a
/// drag seeks.
class VideoTimeline extends StatelessWidget {
  const VideoTimeline({super.key, required this.controller, this.thumb = 6});

  final CommunityVideoController controller;

  /// The thumb's radius: 6 in the card, 7 full screen.
  final double thumb;

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
              child: CustomPaint(painter: _TimelinePainter(_played, thumb)),
            ),
          );
        },
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  const _TimelinePainter(this.played, this.thumb);

  final double played;
  final double thumb;

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
    canvas.drawCircle(Offset(x, y), thumb, Paint()..color = QeranColors.gold);
  }

  @override
  bool shouldRepaint(_TimelinePainter old) =>
      old.played != played || old.thumb != thumb;
}
