import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Image.asset(AppAssets.logo, width: 220)],
          ),
        ),
      ),
    );
  }
}
