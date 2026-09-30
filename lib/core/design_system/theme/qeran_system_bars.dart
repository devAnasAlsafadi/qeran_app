import 'package:flutter/services.dart';

/// System-bar styles for screens that paint their own surface under the
/// status bar. An `AppBar` sets the style for the screens that have one; a
/// screen without one keeps whatever the previous screen left behind unless it
/// states its own.
class QeranSystemBars {
  const QeranSystemBars._();

  /// Dark status-bar icons over a light surface (paper or canvas). Only the
  /// status bar is set; the navigation bar keeps what the platform chose.
  static const SystemUiOverlayStyle darkIcons = SystemUiOverlayStyle(
    statusBarIconBrightness: Brightness.dark, // Android
    statusBarBrightness: Brightness.light, // iOS
  );
}
