import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

extension ResponsiveContext on BuildContext {
  bool get isMobile => ResponsiveBreakpoints.of(this).isMobile;
  bool get isTablet => ResponsiveBreakpoints.of(this).isTablet;
  bool get isDesktop => ResponsiveBreakpoints.of(this).isDesktop;

  bool get isMobileOrTablet => isMobile || isTablet;
}