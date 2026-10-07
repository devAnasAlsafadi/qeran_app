import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qeran/features/community/domain/entities/picked_video.dart';

import '../../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../../core/design_system/widgets/qeran_page_indicator.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../generated/locale_keys.g.dart';
import '../../../../../community/presentation/formatting/video_duration.dart';
import '../../../../../community/presentation/video/community_video_player.dart';
import '../../../../../community/presentation/video/video_player_adapter.dart';
import '../../../../../community/presentation/widgets/post_card/media_geometry.dart';
import '../../../../../community/presentation/widgets/video/video_layers.dart';
import 'composer_remove_button.dart';

/// The composer's video frame's height, while that fits the width.
const double composerPreviewHeight = 260;

/// BA-D: the feed's clamp (4:5 to 16:9) at [composerPreviewHeight], centred,
/// so the text stays in view above it; the full width at its ratio once that
/// would be wider than there is room for, and always at 16:9 (D3). The ratio
/// is the local file's, after rotation — never the server's (K19).
Size composerPreviewSize(double maxWidth, int width, int height) {
  final aspect = clampedAspect(width, height);
  final wide = composerPreviewHeight * aspect;
  if (aspect < kWidestMediaAspect && wide <= maxWidth) {
    return Size(wide, composerPreviewHeight);
  }
  return Size(maxWidth, maxWidth / aspect);
}

/// Her picked video (C6, BA-D1–D3): its first frame contained on wine, the
/// play disc, its length, and × while she can still change it.
class ComposerVideoPreview extends StatefulWidget {
  const ComposerVideoPreview({super.key, required this.video, this.onRemove});

  final PickedVideo video;
  final VoidCallback? onRemove;

  @override
  State<ComposerVideoPreview> createState() => _ComposerVideoPreviewState();
}

class _ComposerVideoPreviewState extends State<ComposerVideoPreview> {
  late final CommunityVideoPlayer _player = _makePlayer(widget.video.path);

  static CommunityLocalVideoPlayerFactory get _makePlayer =>
      sl.isRegistered<CommunityLocalVideoPlayerFactory>()
      ? sl<CommunityLocalVideoPlayerFactory>()
      : VideoPlayerAdapter.file;

  @override
  void initState() {
    super.initState();
    _player.value.addListener(_changed);
    _player.initialize().catchError((Object _) {});
  }

  @override
  void dispose() {
    _player.value.removeListener(_changed);
    _player.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  Future<void> _toggle() async {
    final value = _player.value.value;
    if (value.playing) return _player.pause();
    if (value.completed) await _player.seekTo(Duration.zero);
    await _player.play();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.video.info;
    return LayoutBuilder(
      builder: (context, box) => Center(
        child: SizedBox.fromSize(
          size: composerPreviewSize(box.maxWidth, info.width, info.height),
          child: ClipRRect(
            borderRadius: QeranRadii.controlR,
            child: Stack(fit: StackFit.expand, children: _layers(context)),
          ),
        ),
      ),
    );
  }

  List<Widget> _layers(BuildContext context) {
    final value = _player.value.value;
    final info = widget.video.info;
    return [
      const ColoredBox(color: QeranColors.wine),
      if (value.initialized)
        Center(
          child: AspectRatio(
            aspectRatio: info.width / math.max(info.height, 1),
            child: _player.view(),
          ),
        ),
      if (value.playing)
        GestureDetector(behavior: HitTestBehavior.opaque, onTap: _toggle)
      else
        Center(
          child: VideoPlayDisc(onTap: _toggle, replay: value.completed),
        ),
      ..._corners(context),
    ];
  }

  /// Its length at the bottom start; × at the top end.
  List<Widget> _corners(BuildContext context) => [
    PositionedDirectional(
      bottom: QeranSpacing.s12,
      start: QeranSpacing.s12,
      child: QeranOverlayPill(formatVideoDuration(widget.video.info.duration)),
    ),
    if (widget.onRemove case final remove?)
      PositionedDirectional(
        top: 0,
        end: 0,
        child: ComposerRemoveButton(
          label: LocaleKeys.matchmaker_community_remove_video.t(context),
          onTap: remove,
          disc: 30,
        ),
      ),
  ];
}
