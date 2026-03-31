import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/theme/app_color.dart';

class CustomDotIndicator extends StatelessWidget {
  final PageController controller;
  final int count;

  const CustomDotIndicator({
    super.key,
    required this.controller,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return SmoothPageIndicator(
      controller: controller,
      count: count,
      effect: ExpandingDotsEffect(
        activeDotColor: AppColors.primaryLight,
        dotColor: AppColors.white.withValues(alpha: 0.4),
        dotHeight: 8,
        dotWidth: 8,
        expansionFactor: 3,
        spacing: 6,
      ),
    );
  }
}
