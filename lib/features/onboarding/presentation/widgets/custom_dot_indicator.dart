import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:qeran/core/design_system/tokens/qeran_colors.dart';

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
        activeDotColor: QeranColors.gold,
        dotColor: QeranColors.paper.withValues(alpha: 0.4),
        dotHeight: 8,
        dotWidth: 8,
        expansionFactor: 3,
        spacing: 6,
      ),
    );
  }
}
