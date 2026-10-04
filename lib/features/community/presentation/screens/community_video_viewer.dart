import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/theme/qeran_system_bars.dart';
import '../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/entities/community_media.dart';
import '../video/community_video_controller.dart';
import '../video/community_video_phase.dart';
import '../widgets/community_network_image.dart';
import '../widgets/video/video_layers.dart';
import '../widgets/viewer/viewer_top_bar.dart';
import '../widgets/viewer/viewer_video_panel.dart';

/// A card's video full screen (G4–G7; BA-E1–E3), on wine. It is the card's
/// own player, its place kept (S20), at the video's true ratio — as wide as
/// the screen and centred, or contained when that would be too tall (S22).
/// The disc plays and pauses; rotate turns it landscape until it closes
/// (Q9).
class CommunityVideoViewer extends StatefulWidget {
  const CommunityVideoViewer({
    super.key,
    required this.controller,
    required this.video,
  });

  final CommunityVideoController controller;
  final CommunityVideo video;

  @override
  State<CommunityVideoViewer> createState() => _CommunityVideoViewerState();
}

class _CommunityVideoViewerState extends State<CommunityVideoViewer> {
  bool _landscape = false;

  CommunityVideoController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_changed);
  }

  void _changed() => setState(() {});

  void _rotate() {
    setState(() => _landscape = !_landscape);
    SystemChrome.setPreferredOrientations(
      _landscape
          ? const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [DeviceOrientation.portraitUp],
    );
  }

  @override
  void dispose() {
    _c.removeListener(_changed);
    // Back to whatever the phone allows.
    SystemChrome.setPreferredOrientations(const []);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: QeranSystemBars.lightIcons,
      child: Scaffold(
        backgroundColor: QeranColors.wine,
        body: Stack(children: _layers(_c.phase)),
      ),
    );
  }

  /// Every layer positioned, so the stack fills the screen.
  List<Widget> _layers(CommunityVideoPhase phase) {
    final dimmed =
        phase == CommunityVideoPhase.buffering ||
        phase == CommunityVideoPhase.error;
    return [
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _c.tapPicture,
          child: Center(
            child: AspectRatio(aspectRatio: _ratio, child: _picture()),
          ),
        ),
      ),
      if (dimmed) const Positioned.fill(child: VideoDim()),
      Positioned.fill(child: Center(child: _centre(phase))),
      PositionedDirectional(
        top: 0,
        start: 0,
        end: 0,
        child: ViewerTopBar(onClose: () => Navigator.of(context).maybePop()),
      ),
      if (_panelShown(phase)) _panel(),
    ];
  }

  Widget _panel() => PositionedDirectional(
    start: 0,
    end: 0,
    bottom: MediaQuery.paddingOf(context).bottom + 16,
    child: ViewerVideoPanel(controller: _c, onRotate: _rotate),
  );

  double get _ratio {
    final (w, h) = (widget.video.width, widget.video.height);
    return w > 0 && h > 0 ? w / h : 16 / 9;
  }

  Widget _picture() {
    final player = _c.player;
    if (player != null && player.value.value.initialized) return player.view();
    final poster = widget.video.posterUrl?.trim() ?? '';
    if (poster.isEmpty) return const SizedBox.shrink();
    return CommunityNetworkImage(
      poster,
      fit: BoxFit.contain,
      placeholder: const SizedBox.shrink(),
      fallback: const SizedBox.shrink(),
    );
  }

  /// The controls show as they do on the card: while paused or ended, and
  /// while it plays until they fade.
  bool _panelShown(CommunityVideoPhase phase) =>
      _c.controlsShown || phase == CommunityVideoPhase.ended;

  Widget? _centre(CommunityVideoPhase phase) => switch (phase) {
    CommunityVideoPhase.buffering => const QeranLoader(
      size: 36,
      primary: QeranColors.gold,
      accent: QeranColors.gold,
    ),
    CommunityVideoPhase.error => VideoFailed(onRetry: _c.retry),
    CommunityVideoPhase.playing when !_c.controlsShown => null,
    _ => _Disc(phase: phase, onTap: _c.togglePlay),
  };
}

/// The viewer's disc (G4, G5): dark, its icon in paper — pause while it
/// plays, play when paused, replay once it ended.
class _Disc extends StatelessWidget {
  const _Disc({required this.phase, required this.onTap});

  final CommunityVideoPhase phase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (phase) {
      CommunityVideoPhase.playing => (
        Icons.pause_rounded,
        LocaleKeys.community_video_pause,
      ),
      CommunityVideoPhase.ended => (
        Icons.replay_rounded,
        LocaleKeys.community_video_replay,
      ),
      _ => (Icons.play_arrow_rounded, LocaleKeys.community_video_play),
    };
    return Semantics(
      button: true,
      label: label.t(context),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: QeranColors.overlayTintDark,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 36, color: QeranColors.paper),
        ),
      ),
    );
  }
}
