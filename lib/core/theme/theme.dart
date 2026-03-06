import 'package:flutter/material.dart';
import 'package:qeran/core/constants/app_constants.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'app_color.dart';
import 'app_text_style.dart';

class AppTheme {
  AppTheme._();

  // --- Light Theme ---
  static ThemeData  lightTheme (Locale locale){
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.surface,
      fontFamily: locale.languageCode == 'ar'
          ? AppConstants.fontFamilyArabic
          : AppConstants.fontFamilyEnglish,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: _textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.background,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primary),
        actionsIconTheme: const IconThemeData(color: AppColors.primary),
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: AppColors.primary,
        ),
      ),
      elevatedButtonTheme: _buttonTheme(AppColors.primary, AppColors.white),
      inputDecorationTheme: _inputTheme(AppColors.surface, AppColors.primary),
      cardTheme: _cardTheme(AppColors.white, AppColors.primary),
    );
  }

  // --- Dark Theme ---
  static ThemeData  darkTheme (Locale locale){
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryLight,
      scaffoldBackgroundColor: AppColors.darkBackground,
      fontFamily: locale.languageCode == 'ar'
          ? AppConstants.fontFamilyArabic
          : AppConstants.fontFamilyEnglish,
      colorScheme: const ColorScheme.dark(
        primary:
            AppColors.primaryLight,
        secondary: AppColors.primary,
        surface: AppColors.darkSurface,
        error: AppColors.error,
        onPrimary: AppColors.black,
        onSurface: AppColors.white,
      ),
      textTheme: _textTheme.apply(
        bodyColor: AppColors.white,
        displayColor: AppColors.primaryLight,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.darkBackground,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primaryLight),
        actionsIconTheme: const IconThemeData(color: AppColors.primaryLight),
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: AppColors.primaryLight,
        ),
      ),
      elevatedButtonTheme: _buttonTheme(
        AppColors.primaryLight,
        AppColors.black,
      ),
      inputDecorationTheme: _inputTheme(
        AppColors.darkSurface,
        AppColors.primaryLight,
      ),
      cardTheme: _cardTheme(AppColors.darkSurface, AppColors.primaryLight),
    );
  }



  // --- Helper Methods ---

  static TextTheme get _textTheme => const TextTheme(
    displayLarge: AppTextStyles.displayLarge,
    headlineMedium: AppTextStyles.headlineMedium,
    headlineSmall: AppTextStyles.headlineSmall,
    titleLarge: AppTextStyles.titleLarge,
    bodyLarge: AppTextStyles.bodyLarge,
    bodyMedium: AppTextStyles.bodyMedium,
    labelLarge: AppTextStyles.labelLarge,
    labelSmall: AppTextStyles.labelSmall,
  );

  static ElevatedButtonThemeData _buttonTheme(Color bg, Color fg) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          alignment: Alignment.center,
          textStyle: AppTextStyles.labelLarge.copyWith(
            height: 1.0,
            leadingDistribution: TextLeadingDistribution.even
          ),
          minimumSize: const Size(double.infinity, 55),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: AppDimens.borderRadius12),
        ),
      );

  static InputDecorationTheme _inputTheme(Color fillColor, Color focusColor) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fillColor,
        contentPadding: AppDimens.paddingAll16,
        border: OutlineInputBorder(
          borderRadius: AppDimens.borderRadius12,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimens.borderRadius12,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimens.borderRadius12,
          borderSide: BorderSide(color: focusColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimens.borderRadius12,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: AppTextStyles.caption,
        labelStyle: AppTextStyles.bodyMedium,
      );

  static CardThemeData _cardTheme(Color bgColor, Color shadowColor) =>
      CardThemeData(
        color: bgColor,
        elevation: 4,
        shadowColor: shadowColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: AppDimens.borderRadius16),
      );
}
