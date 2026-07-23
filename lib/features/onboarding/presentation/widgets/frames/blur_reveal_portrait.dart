import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_motion.dart';
import 'package:qeran/core/utils/app_assets.dart';

/// The privacy hero portrait with an animated **blur-reveal seam**: a thin gold
/// vertical line sweeps left↔right across the photo (ping-pong, ease-in-out) and
/// is the moving boundary between two states — HEAVY blur + wine tint on one
/// side, the SAME image under a permanent LIGHT blur on the other. The face is
/// never fully revealed: even the "revealed" side keeps a light blur floor. A
/// literal demo of the app's gradual-unblur privacy mechanic.
///
/// Performance (target: mid-range SM A325F): both blurred images use CONSTANT
/// sigmas inside [RepaintBoundary]s, so each blur rasterises ONCE. The
/// [AnimationController] drives only the seam position + the [ClipRect]
/// boundary; the light floor sits outside the builder and the expensive frosted
/// layer is passed as the [AnimatedBuilder] `child`, so neither is rebuilt (or
/// re-blurred) per frame.
///
/// Reduce-motion: when [MediaQueryData.disableAnimations] is set, no ticker runs
/// — a single static frame is painted with the seam centred (the half/half
/// look), matching the splash's reduce-motion contract.
///
/// The sweep runs in raw coordinates (physical left→right); the ping-pong is
/// symmetric, so there is no locale-dependent direction and no manual `isRtl`
/// swap — the surrounding layout stays `*Directional`.
class BlurRevealPortrait extends StatefulWidget {
  const BlurRevealPortrait({super.key});

  @override
  State<BlurRevealPortrait> createState() => _BlurRevealPortraitState();
}

class _BlurRevealPortraitState extends State<BlurRevealPortrait>
    with SingleTickerProviderStateMixin {
  /// Permanent "revealed-soft" floor — deliberately low so the shown side reads
  /// clearly (the face is recognisable), while never going 100% sharp. That
  /// whisper of softness keeps the "الصورة محمية" promise honest; set to 0 for a
  /// fully-sharp reveal. Paired with [_heavyBlurSigma], the two visible states
  /// read at clearly different degrees.
  static const double _lightBlurSigma = 1.5;

  /// The frosted side hidden behind the seam — strong enough that the face is
  /// clearly protected there (was the reference mock's `blur(9px)`).
  static const double _heavyBlurSigma = 9;

  /// Width of the moving gold boundary line (reference mock: 3px).
  static const double _seamWidth = 3;

  /// Reduce-motion seam position — centred (the static half/half frame).
  static const double _staticSeamFraction = 0.5;

  AnimationController? _controller;
  CurvedAnimation? _sweep;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduce-motion and page-level TickerMode both remain respected. If the
    // accessibility setting changes at runtime, dispose/recreate the ticker
    // without changing the half-blurred visual.
    if (MediaQuery.of(context).disableAnimations) {
      _sweep?.dispose();
      _sweep = null;
      _controller?.dispose();
      _controller = null;
      return;
    }
    if (_controller != null) return;
    final controller = AnimationController(
      vsync: this,
      duration: QeranMotion.revealSweep,
    )..repeat(reverse: true);
    _controller = controller;
    _sweep = CurvedAnimation(
      parent: controller,
      curve: QeranCurves.revealSweep,
      reverseCurve: QeranCurves.revealSweep,
    );
  }

  @override
  void dispose() {
    _sweep?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      // Wine base shows while the asset decodes (mirrors the old portrait).
      color: QeranColors.wine,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final softFloor = _blurredImage(_lightBlurSigma);
          final frostedLayer = _frostedLayer(); // built once; reused per frame
          final sweep = _sweep;
          return Stack(
            fit: StackFit.expand,
            children: [
              softFloor,
              if (sweep == null)
                ..._revealLayers(width * _staticSeamFraction, frostedLayer)
              else
                AnimatedBuilder(
                  animation: sweep,
                  child: frostedLayer,
                  builder: (context, child) => Stack(
                    fit: StackFit.expand,
                    children: _revealLayers(sweep.value * width, child!),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// The clipped frosted layer + the gold seam for a given [seamX]. Shared by
  /// the animated and reduce-motion paths so they stay pixel-identical.
  List<Widget> _revealLayers(double seamX, Widget frostedLayer) {
    return [
      ClipRect(clipper: _LeftClipper(seamX), child: frostedLayer),
      Positioned(
        key: const ValueKey<String>('onboarding-blur-reveal-seam'),
        left: seamX - _seamWidth / 2,
        top: 0,
        bottom: 0,
        width: _seamWidth,
        child: const _GoldSeam(),
      ),
    ];
  }

  /// HEAVY blur + wine tint, rasterised once behind a [RepaintBoundary].
  Widget _frostedLayer() {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _blurredImage(_heavyBlurSigma),
          const ColoredBox(color: QeranColors.overlayTintDark),
        ],
      ),
    );
  }

  /// The same portrait at [sigma] blur, cached in its own [RepaintBoundary].
  Widget _blurredImage(double sigma) {
    return RepaintBoundary(
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: const Image(
          image: AssetImage(AppAssets.welcomePortrait),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
        ),
      ),
    );
  }
}

/// Clips its child to the region LEFT of [seamX] (raw coordinates — the frosted
/// half is always physical-left, in both LTR and RTL).
class _LeftClipper extends CustomClipper<Rect> {
  const _LeftClipper(this.seamX);

  final double seamX;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, seamX.clamp(0.0, size.width), size.height);

  @override
  bool shouldReclip(_LeftClipper oldClipper) => oldClipper.seamX != seamX;
}

/// The thin gold seam line with a soft, low-alpha gold glow on both sides.
class _GoldSeam extends StatelessWidget {
  const _GoldSeam();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: QeranColors.gold,
        boxShadow: [
          BoxShadow(color: QeranColors.gold40, blurRadius: 12, spreadRadius: 1),
          BoxShadow(color: QeranColors.gold20, blurRadius: 22, spreadRadius: 3),
        ],
      ),
    );
  }
}
