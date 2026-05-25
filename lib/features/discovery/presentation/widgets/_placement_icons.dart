import 'package:flutter/material.dart';

/// Best-effort mapping from server `questionId` → Material icon for chip
/// display.
///
/// The API ships no icon metadata today; this lookup is hardcoded by the
/// observed question taxonomy in the sample response. New questionIds
/// fall back to a neutral dot. When the backend adds icon metadata,
/// delete this file and consume the field directly on `PlacementItem`.
IconData iconForQuestionId(int questionId) {
  return switch (questionId) {
    // Above-image placement (location / job / nationality)
    9 => Icons.location_on_outlined,
    10 => Icons.work_outline_rounded,
    11 => Icons.public_outlined,
    // Inside-card placement (weight / height / skin / eyes / marital)
    4 => Icons.monitor_weight_outlined,
    5 => Icons.height_rounded,
    6 => Icons.palette_outlined,
    7 => Icons.remove_red_eye_outlined,
    18 => Icons.favorite_border_rounded,
    _ => Icons.circle,
  };
}
