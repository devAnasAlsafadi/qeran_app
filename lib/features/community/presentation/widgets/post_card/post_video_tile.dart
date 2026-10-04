import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_page_indicator.dart';
import '../../../domain/entities/community_media.dart';
import '../../formatting/video_duration.dart';
import '../../video/community_video_controller.dart';
import '../../video/community_video_phase.dart';
import '../../screens/community_media_viewer.dart';
import '../../video/community_video_scope.dart';
import '../community_network_image.dart';
import '../video/video_controls_bar.dart';
import '../video/video_layers.dart';
import 'media_geometry.dart';

/// A video post's frame (A9–A14; BA-B1–B4 in the feed, BA-C1–C3 on the post
/// screen). The frame takes the video's own ratio clamped between 4:5 and
/// 16:9 (16:9 without a size), and the poster, then the video, is contained
/// in it on wine — never cropped. The poster and the video are signed links,
/// loaded without our token. A tap on the disc plays it, through the
/// screen's [CommunityVideoScope]; it pauses when another video starts, its
/// tab is hidden, a route covers it, or the app leaves the foreground (Q9).
class PostVideoTile extends StatefulWidget {
  const PostVideoTile({super.key, required this.postId, required this.video});

  final int postId;
  final CommunityVideo video;

  @override
  State<PostVideoTile> createState() => _PostVideoTileState();
}

class _PostVideoTileState extends State<PostVideoTile>
    with WidgetsBindingObserver {
  CommunityVideoController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(PostVideoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video != widget.video) _controller?.video = widget.video;
  }

  /// A hidden tab or a route over this one pauses it.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shown =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    // Full screen, the viewer is over it on purpose: it keeps playing.
    if (!shown && !(_controller?.handedOver ?? false)) _controller?.suspend();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_leavesForeground(state)) _controller?.suspend();
  }

  /// Android leaves at `hidden` / `paused`; iOS already at `inactive` (D12,
  /// the privacy shield's rule).
  static bool _leavesForeground(AppLifecycleState state) =>
      state == AppLifecycleState.paused ||
      state == AppLifecycleState.hidden ||
      (state == AppLifecycleState.inactive &&
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  CommunityVideoController? _ensure() {
    final scope = CommunityVideoScope.maybeOf(context);
    if (scope == null) return null;
    return _controller ??= scope.controllerFor(widget.postId, widget.video)
      ..addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s12),
      child: ClipRRect(
        borderRadius: QeranRadii.controlR,
        child: AspectRatio(
          aspectRatio: clampedAspect(widget.video.width, widget.video.height),
          child: ColoredBox(
            color: QeranColors.wine,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _controller?.tapPicture(),
              child: Stack(fit: StackFit.expand, children: _layers()),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _layers() {
    final c = _controller;
    final phase = c?.phase ?? CommunityVideoPhase.idle;
    final dimmed = const {
      CommunityVideoPhase.buffering,
      CommunityVideoPhase.ended,
      CommunityVideoPhase.error,
    }.contains(phase);
    return [
      _picture(c),
      const VideoBottomGradient(),
      if (dimmed) const VideoDim(),
      Center(child: _centre(c, phase)),
      if (phase == CommunityVideoPhase.idle &&
          widget.video.duration > Duration.zero)
        _length(),
      if (c != null && c.controlsShown) _controls(c),
    ];
  }

  /// The bar along the bottom, with full screen (A11, G4).
  Widget _controls(CommunityVideoController c) => PositionedDirectional(
    start: 0,
    end: 0,
    bottom: 0,
    child: VideoControlsBar(
      controller: c,
      onFullScreen: () =>
          openCommunityVideo(context, controller: c, video: widget.video),
    ),
  );

  /// The length, at the bottom start, before it plays (A9).
  Widget _length() => PositionedDirectional(
    bottom: QeranSpacing.s12,
    start: QeranSpacing.s12,
    child: QeranOverlayPill(formatVideoDuration(widget.video.duration)),
  );

  /// The video once it has a picture, contained at its own ratio; the
  /// poster until then.
  Widget _picture(CommunityVideoController? c) {
    final player = c?.player;
    if (player != null && player.value.value.initialized && !c!.handedOver) {
      return Center(
        child: AspectRatio(aspectRatio: _videoRatio, child: player.view()),
      );
    }
    final poster = widget.video.posterUrl?.trim() ?? '';
    if (poster.isEmpty) return const SizedBox.shrink();
    return CommunityNetworkImage(
      poster,
      fit: BoxFit.contain,
      placeholder: const SizedBox.shrink(),
      fallback: const SizedBox.shrink(),
    );
  }

  double get _videoRatio {
    final (w, h) = (widget.video.width, widget.video.height);
    return w > 0 && h > 0 ? w / h : 16 / 9;
  }

  Widget? _centre(CommunityVideoController? c, CommunityVideoPhase phase) =>
      switch (phase) {
        CommunityVideoPhase.idle || CommunityVideoPhase.paused => VideoPlayDisc(
          onTap: _playable ? () => _ensure()?.play() : null,
        ),
        CommunityVideoPhase.ended => VideoPlayDisc(
          replay: true,
          onTap: c?.play,
        ),
        CommunityVideoPhase.buffering => const VideoBufferingDisc(),
        CommunityVideoPhase.error => VideoFailed(onRetry: () => c?.retry()),
        CommunityVideoPhase.playing => null,
      };

  /// Only its author ever sees one that isn't ready (no link yet).
  bool get _playable => (widget.video.url?.trim() ?? '').isNotEmpty;
}
