import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/features/splash/presentation/screens/splash_screen_controller.dart';
import '../blocs/splash_cubit.dart';
import '../blocs/splash_state.dart';

/// The Flutter splash: plays the brand Lottie centred on a full-bleed wine
/// canvas (edge-to-edge, painting under the status/navigation bars) and hands
/// off to the next route.
///
/// The reveal is driven by a [Ticker] that advances the Lottie controller's
/// `value` 0→1 by hand — NOT `AnimationController.forward()`. The framework's
/// animate methods honor the OS `disableAnimations` flag (Android "Animator
/// duration scale = Off" / reduce-motion) and would jump straight to the end,
/// freezing the reveal; a Ticker + direct `value` set are not gated by that
/// flag, so the logo animates on EVERY device and can never freeze on a blank
/// frame.
///
/// Timing is animation-driven but hang-proof: navigation fires only when BOTH
/// the animation is done AND the routing decision (session / role / progress)
/// has arrived. The animation half settles three ways — the reveal reaching its
/// end, a load/parse error, or a safety timeout — so a broken or slow animation
/// degrades to "route as soon as the decision is ready" instead of hanging. The
/// routing brain (SplashCubit + SplashScreenController + bootstrap) is unchanged.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const String _animationAsset = 'assets/animations/logo_qeran_v3.json';

  /// Backstop: force the animation gate open if nothing else has within this
  /// cap (comfortably over the full reveal), so a stalled/never-loading
  /// animation can never hang the splash. The real reveal length is read from
  /// the composition at runtime (see [_startReveal]); this is only an upper bound.
  static const Duration _safetyCap = Duration(seconds: 6);

  /// Used only if the composition reports a non-positive duration.
  static const Duration _fallbackDuration = Duration(milliseconds: 4000);

  /// The transparent logo+wordmark art (1080×795) is centred on the wine canvas
  /// at this fraction of the screen width — sized, not full-bleed — so it never
  /// reaches the edges. Height follows from the art's aspect ratio.
  static const double _logoWidthFraction = 0.72;

  late final SplashScreenController _controller;

  /// Value-holder [Animation] the Lottie renders from. We NEVER call
  /// `forward()` on it — [_revealTicker] sets its `value` directly, so playback
  /// bypasses the OS `disableAnimations` flag and can't freeze on frame 0.
  late final AnimationController _anim;

  /// Hand-drives [_anim].value across the composition duration.
  Ticker? _revealTicker;
  Timer? _safetyTimer;

  /// The route decision from [SplashCubit] — null until it resolves.
  SplashState? _pending;

  /// True once the animation is done for ANY reason (reveal complete / error /
  /// timeout).
  bool _animDone = false;

  /// Guards against navigating more than once when both gates are satisfied.
  bool _navigated = false;

  /// Guards the deferred settle from the error path against re-scheduling on
  /// every rebuild.
  bool _errorSettleScheduled = false;

  /// Guards [_startReveal] so a rebuild / hot-reload can't restart the reveal
  /// mid-play.
  bool _revealStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = SplashScreenController(context);
    _anim = AnimationController(vsync: this);
    // Backstop timer — cancelled by the first settle (see _markAnimationSettled)
    // or in dispose.
    _safetyTimer = Timer(_safetyCap, _markAnimationSettled);
    // Kick off the routing decision + device bootstrap (unchanged).
    _controller.init();
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _revealTicker?.dispose();
    _anim.dispose();
    super.dispose();
  }

  /// Drive the reveal: a [Ticker] advances [_anim].value 0→1 across [duration],
  /// independent of any `forward()` call — so the OS reduce-motion /
  /// animator-scale flag can't skip it. Idempotent (guarded by [_revealStarted]).
  /// Settles the animation gate when the reveal reaches its end.
  void _startReveal(Duration duration) {
    if (_revealStarted) return;
    _revealStarted = true;
    final totalUs = duration.inMicroseconds <= 0
        ? _fallbackDuration.inMicroseconds
        : duration.inMicroseconds;
    _revealTicker = createTicker((elapsed) {
      final t = (elapsed.inMicroseconds / totalUs).clamp(0.0, 1.0);
      _anim.value = t; // direct set — NOT forward(); ignores disableAnimations
      if (t >= 1.0) {
        _revealTicker?.stop();
        _markAnimationSettled();
      }
    })..start();
  }

  /// Flip the animation gate no matter WHY the animation is done — reveal
  /// complete, a load/parse error, or the safety timeout — then try to navigate.
  /// Idempotent: the guards in [_maybeNavigate] handle repeats.
  void _markAnimationSettled() {
    _safetyTimer?.cancel();
    _animDone = true;
    _maybeNavigate();
  }

  /// Navigate only when BOTH the animation is done AND the routing decision has
  /// arrived — and never more than once.
  void _maybeNavigate() {
    if (_navigated || !_animDone || _pending == null) return;
    _navigated = true;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _controller.handleNavigation(_pending!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
          // Full-bleed wine background (paints under the system bars too). The
          // transparent logo art (1080×795) is centred on top at
          // [_logoWidthFraction] of the screen width with BoxFit.contain — sized,
          // not stretched, so it never distorts or reaches the edges.
          body: SizedBox.expand(
            child: ColoredBox(
              color: QeranColors.wine,
              child: Center(
                child: Lottie.asset(
                  _animationAsset,
                  controller: _anim,
                  width: MediaQuery.of(context).size.width * _logoWidthFraction,
                  fit: BoxFit.contain,
                  // A load/parse/render failure must NOT hang the splash: log
                  // it and settle the animation gate (deferred — errorBuilder
                  // runs during build, and we must not navigate mid-build) so
                  // we route on the decision instead of showing a blank forever.
                  errorBuilder: (context, error, stack) {
                    AppLogger.error(
                      'Splash Lottie failed to load/render',
                      error: error,
                      stack: stack,
                      tag: 'SPLASH',
                    );
                    if (!_animDone && !_errorSettleScheduled) {
                      _errorSettleScheduled = true;
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => _markAnimationSettled());
                    }
                    return const SizedBox.shrink();
                  },
                  // Start the hand-driven reveal once the composition is ready.
                  onLoaded: (composition) => _startReveal(composition.duration),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
