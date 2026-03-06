import 'package:flutter/material.dart';

class AppDimens {
  //  (Base Scales)
  static const double p4 = 4.0;
  static const double p8 = 8.0;
  static const double p12 = 12.0;
  static const double p16 = 16.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
  static const double p32 = 32.0;
  static const double p48 = 48.0;

  //  (Border Radius)
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;

  static final BorderRadius borderRadius8 = BorderRadius.circular(r8);
  static final BorderRadius borderRadius12 = BorderRadius.circular(r12);
  static final BorderRadius borderRadius16 = BorderRadius.circular(r16);

  //  (Padding/Margins)
  static const EdgeInsets paddingAll8 = EdgeInsets.all(p8);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(p16);
  static const EdgeInsets paddingH16V8 = EdgeInsets.symmetric(horizontal: p16, vertical: p8);

  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(vertical: p8, horizontal: p24);

  //  (SizedBoxes)
  static const verticalSpace8 = SizedBox(height: p8);
  static const verticalSpace16 = SizedBox(height: p16);
  static const verticalSpace24 = SizedBox(height: p24);
  static const horizontalSpace8 = SizedBox(width: p8);
}