import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'app_color.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    fontFamily: AppConstants.fontFamilyArabic,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    fontFamily: AppConstants.fontFamilyArabic,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: AppConstants.fontFamilyArabic,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    fontFamily: AppConstants.fontFamilyArabic,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: AppConstants.fontFamilyArabic,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: AppConstants.fontFamilyArabic,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    fontFamily: AppConstants.fontFamilyArabic,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    fontFamily: AppConstants.fontFamilyArabic,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: AppConstants.fontFamilyArabic,
  );
}