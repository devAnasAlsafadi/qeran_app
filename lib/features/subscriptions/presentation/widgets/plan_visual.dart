import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';

/// Safe parsing helpers for the dashboard-controlled `plan.color` (any
/// `#RRGGBB`) and `plan.icon` (emoji or absolute URL) so a malformed
/// value can never crash the UI.
class PlanVisual {
  const PlanVisual._();

  static final RegExp _hexColorRegex = RegExp(r'^#[0-9A-Fa-f]{6}$');

  /// Parses `#RRGGBB` into a Flutter [Color]. Falls back to
  /// [AppColors.primary] for any malformed value (empty, wrong length,
  /// non-hex characters, missing `#`).
  static Color parseColor(String raw) {
    if (!_hexColorRegex.hasMatch(raw)) return AppColors.primary;
    return Color(int.parse(raw.substring(1), radix: 16) | 0xFF000000);
  }

  /// Returns `true` when [raw] looks like a fully-qualified URL the
  /// network image loader can fetch. Anything else (emoji glyphs,
  /// whitespace, garbage) renders as text.
  static bool isUrl(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return false;
    return uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }
}
