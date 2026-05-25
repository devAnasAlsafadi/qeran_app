import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../tokens/qeran_colors.dart';
import '../tokens/qeran_radii.dart';
import '../tokens/qeran_typography.dart';

/// Composes [ThemeData] from Qeran tokens.
///
/// Cream canvas is the scaffold background. Font family resolves
/// per-locale (NotoKufiArabic / Montserrat); individual text styles
/// do not hardcode a family so the swap propagates.
class QeranTheme {
  const QeranTheme._();

  static ThemeData light(Locale locale) {
    final fontFamily = locale.languageCode == 'ar'
        ? AppConstants.fontFamilyArabic
        : AppConstants.fontFamilyEnglish;

    final textTheme = _buildTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      primaryColor: QeranColors.wine,
      scaffoldBackgroundColor: QeranColors.creamCanvas,
      canvasColor: QeranColors.creamCanvas,
      dividerColor: QeranColors.divider,
      colorScheme: const ColorScheme.light(
        primary: QeranColors.wine,
        onPrimary: QeranColors.paper,
        secondary: QeranColors.gold,
        onSecondary: QeranColors.wine,
        surface: QeranColors.paper,
        onSurface: QeranColors.inkStrong,
        error: QeranColors.danger,
        onError: QeranColors.paper,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: QeranColors.creamCanvas,
        foregroundColor: QeranColors.wine,
        centerTitle: true,
        iconTheme: IconThemeData(color: QeranColors.wine),
        actionsIconTheme: IconThemeData(color: QeranColors.wine),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.30,
          color: QeranColors.inkStrong,
        ),
      ),
      cardTheme: const CardThemeData(
        color: QeranColors.paper,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: QeranRadii.cardR),
      ),
      dividerTheme: const DividerThemeData(
        color: QeranColors.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: QeranColors.wine),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: QeranColors.paper,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: QeranRadii.controlR,
          borderSide: BorderSide(color: QeranColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: QeranRadii.controlR,
          borderSide: BorderSide(color: QeranColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: QeranRadii.controlR,
          borderSide: BorderSide(color: QeranColors.wine, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: QeranRadii.controlR,
          borderSide: BorderSide(color: QeranColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: QeranRadii.controlR,
          borderSide: BorderSide(color: QeranColors.danger, width: 1.5),
        ),
      ),
      splashColor: QeranColors.wine08,
      highlightColor: QeranColors.wine06,
    );
  }

  static TextTheme _buildTextTheme() {
    return const TextTheme(
      displayLarge: QeranTypography.displayLg,
      displayMedium: QeranTypography.displaySm,
      displaySmall: QeranTypography.displaySm,
      headlineMedium: QeranTypography.headline,
      headlineSmall: QeranTypography.headline,
      titleLarge: QeranTypography.title,
      titleMedium: QeranTypography.subtitle,
      titleSmall: QeranTypography.label,
      bodyLarge: QeranTypography.body,
      bodyMedium: QeranTypography.body,
      bodySmall: QeranTypography.bodySm,
      labelLarge: QeranTypography.label,
      labelMedium: QeranTypography.label,
      labelSmall: QeranTypography.caption,
    );
  }
}
