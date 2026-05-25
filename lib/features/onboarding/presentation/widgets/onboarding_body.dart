import 'package:flutter/material.dart';

class OnboardingBody extends StatelessWidget {
  final String imagePath;

  const OnboardingBody({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(child: Image.asset(imagePath, fit: BoxFit.cover));
  }
}
