import 'package:flutter/material.dart';
import 'package:qeran/core/utils/app_assets.dart';

class AuthLogoHeader extends StatelessWidget {
  const AuthLogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        AppAssets.logo,
        height: 120,
        width: 120,
        fit: BoxFit.contain,
      ),
    );
  }
}

