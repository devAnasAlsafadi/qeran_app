import 'dart:async';

import 'package:flutter/material.dart';
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
/// Timing is animation-driven but hang-proof: navigation fires only when BOTH
/// the animation is done AND the routing decision (session / role / progress)
/// has arrived. The animation half can settle four ways — normal completion, a
/// load/parse error, a safety timeout, or reduce-motion — so a broken or slow
/// animation degrades to "route as soon as the decision is ready" instead of
/// hanging. The routing brain (SplashCubit + SplashScreenController + bootstrap)
/// is unchanged; only the navigation TRIGGER moved off a fixed delay.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const String _animationAsset = 'assets/animations/logo_qeran_v3.json';

  /// Backstop: force the animation gate open if nothing else has within this
  /// cap (comfortably over the ~3.6s Lottie), so a stalled/never-completing
  /// animation can never hang the splash. The real play duration is read from
  /// the composition at runtime (see onLoaded), so this is only an upper bound.
  static const Duration _safetyCap = Duration(seconds: 6);

  late final SplashScreenController _controller;
  late final AnimationController _anim;
  Timer? _safetyTimer;

  /// The route decision from [SplashCubit] — null until it resolves.
  SplashState? _pending;

  /// True once the animation is done for ANY reason (completion / error /
  /// timeout / reduce-motion).
  bool _animDone = false;

  /// Guards against navigating more than once when both gates are satisfied.
  bool _navigated = false;

  /// Guards the deferred settle from the error path against re-scheduling on
  /// every rebuild.
  bool _errorSettleScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = SplashScreenController(context);
    _anim = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _markAnimationSettled();
      });
    // Backstop timer — cancelled by the first settle (see _markAnimationSettled)
    // or in dispose.
    _safetyTimer = Timer(_safetyCap, _markAnimationSettled);
    // Kick off the routing decision + device bootstrap (unchanged).
    _controller.init();
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  /// Flip the animation gate no matter WHY the animation is done — normal
  /// completion, a load/parse error, the safety timeout, or reduce-motion — then
  /// try to navigate. Idempotent: the guards in [_maybeNavigate] handle repeats.
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
    _controller.handleNavigation(_pending!);
  }

  @override
  Widget build(BuildContext context) {
    // Respect the OS "reduce motion" setting: skip the animation gate and route
    // as soon as the decision is ready (fast path, no forced ~5s wait).
    final reduceMotion = MediaQuery.of(context).disableAnimations;

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
          if (reduceMotion) {
            _markAnimationSettled();
          } else {
            _maybeNavigate();
          }
        },
        child: Scaffold(
          backgroundColor: QeranColors.wine,
          // Full-bleed wine: no SafeArea, no insets — it paints to all four
          // edges (including behind the system bars) with the Lottie centred on
          // top. `contain` still letterboxes the 9:16 composition on taller
          // screens, but those gaps are now wine instead of the old cream
          // canvas that showed through as white bars.
          body: SizedBox.expand(
            child: ColoredBox(
              color: QeranColors.wine,
              child: Center(
                child: Lottie.asset(
                  _animationAsset,
                  controller: _anim,
                  fit: BoxFit.contain,
                  // A load/parse/render failure must NOT hang the splash: log
                  // it and settle the animation gate (deferred — errorBuilder
                  // runs during build, and we must not navigate mid-build) so
                  // we route on the decision instead of showing a blank
                  // forever.
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
                  onLoaded: (composition) {
                    // Under reduce-motion we don't play — navigation is driven
                    // by the decision arriving (handled in the listener above).
                    if (reduceMotion) return;
                    _anim
                      ..duration = composition.duration
                      ..forward();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
