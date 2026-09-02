import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/widgets/privacy_shield_suppression.dart';
import 'package:qeran/features/splash/presentation/splash_reveal_policy.dart';
import 'package:qeran/features/splash/presentation/splash_video.dart';
import 'package:qeran/features/splash/presentation/screens/splash_screen_controller.dart';
import 'package:video_player/video_player.dart';
import '../blocs/splash_cubit.dart';
import '../blocs/splash_state.dart';

/// The Flutter splash: plays the brand animation centred on a full-bleed wine
/// canvas and hands off to the next route.
///
/// The animation is the approved MP4 rather than a Lottie export. Three of the
/// complaints about the Lottie were not fixable in that format at all: the glow
/// is a layer effect the renderer silently drops, the export was a 1080x795
/// banner where the approved piece is 1080x1920 portrait, and the format cannot
/// carry audio.
///
/// Timing is animation-driven but hang-proof: navigation fires only when BOTH
/// the animation is done AND the routing decision (session / role / progress)
/// has arrived. The animation half settles four ways — playback reaching the
/// end, a load or playback error, a tap, or the safety backstop — so a broken
/// or slow animation degrades to "route as soon as the decision is ready"
/// instead of hanging.
///
/// Playback lives in [SplashVideo] and the arithmetic in [SplashRevealPolicy];
/// what is left here is the canvas, the gate, and the handoff.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _animationAsset =
      'assets/animations/logo_qeran_v8_silent.mp4';

  static const SplashRevealPolicy _policy = SplashRevealPolicy();

  late final SplashScreenController _controller;
  late final SplashVideo _video;
  Timer? _safetyTimer;

  /// The route decision from [SplashCubit] — null until it resolves.
  SplashState? _pending;

  /// True once the animation is done for ANY reason (playback complete /
  /// error / tap / backstop).
  bool _animDone = false;

  /// Guards against navigating more than once when both gates are satisfied.
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = SplashScreenController(context);
    // Stand the privacy shield down for as long as this screen is up. Its fill
    // is the same wine as this canvas, so when a system alert (the first-launch
    // notification prompt) takes the app out of `resumed`, the screen still
    // looks right and the animation is simply gone. There is nothing on a logo
    // screen worth hiding.
    privacyShieldSuppressed.value = true;
    _video = SplashVideo(
      asset: _animationAsset,
      onSettled: _markAnimationSettled,
      policy: _policy,
      onError: (message, error, stack) =>
          AppLogger.error(message, error: error, stack: stack, tag: 'SPLASH'),
    );
    // Backstop timer — cancelled by the first settle (see _markAnimationSettled)
    // or in dispose.
    _safetyTimer = Timer(_policy.safetyCap, _markAnimationSettled);
    unawaited(_startPlayback());
    // Hydrate the session and resolve the route while the animation is visible.
    unawaited(_controller.init());
  }

  @override
  void dispose() {
    // Restored before the next route paints, so every screen that DOES hold
    // private content gets the shield back.
    privacyShieldSuppressed.value = false;
    _safetyTimer?.cancel();
    unawaited(_video.dispose());
    super.dispose();
  }

  Future<void> _startPlayback() async {
    await _video.start();
    if (!mounted) return;
    // Repaint so the canvas swaps from bare wine to the first frame.
    setState(() {});
  }

  /// Flip the animation gate no matter WHY the animation is done, then try to
  /// navigate. Idempotent: the guards in [_maybeNavigate] handle repeats.
  void _markAnimationSettled() {
    _safetyTimer?.cancel();
    _animDone = true;
    _maybeNavigate();
  }

  /// Navigate only when BOTH the animation is done AND the routing decision has
  /// arrived — and never more than once.
  void _maybeNavigate() {
    final go = _policy.shouldNavigate(
      animationSettled: _animDone,
      decisionReady: _pending != null,
      alreadyNavigated: _navigated,
    );
    if (!go) return;
    _navigated = true;
    _controller.handleNavigation(_pending!);
  }

  @override
  Widget build(BuildContext context) {
    final player = _video.controller;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Wine runs under the system bars, so their icons must be light to stay
      // legible. `statusBarColor` covers pre-edge-to-edge Android; on
      // edge-to-edge the wine Scaffold below simply shows through instead.
      value: const SystemUiOverlayStyle(
        statusBarColor: QeranColors.wine,
        statusBarIconBrightness: Brightness.light, // Android
        statusBarBrightness: Brightness.dark, // iOS
        systemNavigationBarColor: QeranColors.wine,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: BlocListener<SplashCubit, SplashState>(
        listener: (context, state) {
          _pending = state;
          _maybeNavigate();
        },
        child: Scaffold(
          backgroundColor: QeranColors.wine,
          body: GestureDetector(
            // Skipping settles the animation half only; the decision half still
            // has to arrive, so an impatient tap can never outrun routing.
            onTap: _markAnimationSettled,
            behavior: HitTestBehavior.opaque,
            child: SizedBox.expand(
              child: ColoredBox(
                color: QeranColors.wine,
                // Nothing is painted until there is a real frame, so the wine
                // canvas covers the gap instead of a black rectangle.
                child: player == null ? null : _VideoFrame(video: player),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The playing asset at its authored aspect ratio, centred on the canvas.
///
/// `contain`, never `cover`: this composition was approved as it is, and
/// cropping it to fill a taller phone would ship something nobody signed off.
/// The wine canvas absorbs whatever is left over, and the asset is portrait, so
/// there is very little of it.
class _VideoFrame extends StatelessWidget {
  const _VideoFrame({required this.video});

  final VideoPlayerController video;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: video.value.aspectRatio,
        child: VideoPlayer(video),
      ),
    );
  }
}
