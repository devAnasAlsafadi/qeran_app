import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/effects/ring_motif.dart';
import 'package:qeran/core/design_system/motion/soft_scale_in.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_motion.dart';
import 'package:qeran/features/splash/presentation/screens/splash_screen_controller.dart';
import '../../../../core/utils/app_assets.dart';
import '../blocs/splash_cubit.dart';
import '../blocs/splash_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late SplashScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SplashScreenController(context);
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) => _controller.handleNavigation(state),
      child: Scaffold(
        backgroundColor: QeranColors.creamCanvas,
        body: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Two concentric ring motifs flank the logo — gold at 8%
              // and 5% — for the quiet luxury flourish the identity calls
              // for. Fade in slightly before the logo so the room is set
              // when the mark arrives.
              SoftScaleIn(
                duration: QeranMotion.hero,
                beginScale: 0.92,
                child: const RingMotif(
                  color: QeranColors.gold,
                  opacity: 0.08,
                  size: 320,
                  ringCount: 2,
                  spacing: 22,
                ),
              ),
              SoftScaleIn(
                delay: const Duration(milliseconds: 120),
                duration: QeranMotion.hero,
                beginScale: 0.90,
                child: Image.asset(AppAssets.logo, width: 220),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
