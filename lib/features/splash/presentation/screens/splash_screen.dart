import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/features/splash/presentation/screens/splash_screen_controller.dart';
import '../blocs/splash_cubit.dart';
import '../blocs/splash_state.dart';

/// The Flutter splash: plays the brand Lottie on the soft-white canvas (seamless
/// with the OS native splash, same #F8F8F8) and hands off to the next route.
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
  static const String _animationAsset = 'assets/animations/logo_qeran.json';

  /// Backstop: force the animation gate open if nothing else has within this
  /// cap (just over the ~5.2s Lottie), so a stalled/never-completing animation
  /// can never hang the splash.
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
    // TEMP-DIAG: gate state each time either gate changes.
    AppLogger.debug(
      'TEMP-DIAG _maybeNavigate: navigated=$_navigated animDone=$_animDone '
      'pending=${_pending.runtimeType}',
      tag: 'SPLASH',
    );
    if (_navigated || !_animDone || _pending == null) return;
    _navigated = true;
    // TEMP-DIAG: about to hand off to the router (both gates satisfied).
    AppLogger.debug(
      'TEMP-DIAG reached handleNavigation for ${_pending.runtimeType}',
      tag: 'SPLASH',
    );
    _controller.handleNavigation(_pending!);
  }

  @override
  Widget build(BuildContext context) {
    // Respect the OS "reduce motion" setting: skip the animation gate and route
    // as soon as the decision is ready (fast path, no forced ~5s wait).
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        // TEMP-DIAG: decision arrived.
        AppLogger.debug(
          'TEMP-DIAG listener: pending=${state.runtimeType} '
          'reduceMotion=$reduceMotion',
          tag: 'SPLASH',
        );
        _pending = state;
        if (reduceMotion) {
          _markAnimationSettled();
        } else {
          _maybeNavigate();
        }
      },
      child: Scaffold(
        backgroundColor: QeranColors.creamCanvas,
        body: Center(
          child: Lottie.asset(
            _animationAsset,
            controller: _anim,
            fit: BoxFit.contain,
            // A load/parse/render failure must NOT hang the splash: log it and
            // settle the animation gate (deferred — errorBuilder runs during
            // build, and we must not navigate mid-build) so we route on the
            // decision instead of showing a blank forever.
            errorBuilder: (context, error, stack) {
              AppLogger.error(
                'TEMP-DIAG Lottie FAILED to load/render',
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
              // TEMP-DIAG: composition parsed OK.
              AppLogger.debug(
                'TEMP-DIAG onLoaded: duration=${composition.duration} '
                'reduceMotion=$reduceMotion',
                tag: 'SPLASH',
              );
              // Under reduce-motion we don't play — navigation is driven by the
              // decision arriving (handled in the listener above).
              if (reduceMotion) return;
              _anim
                ..duration = composition.duration
                ..forward();
            },
          ),
        ),
      ),
    );
  }
}
