import 'package:flutter/animation.dart';

/// Motion vocabulary for Qeran. Every animation in the app picks a
/// duration from this set and a curve from [QeranCurves].
class QeranMotion {
  const QeranMotion._();

  /// Tap feedback, chip selection, micro-interactions.
  static const Duration fast = Duration(milliseconds: 180);

  /// Card swap, snackbar entry, content fade.
  static const Duration standard = Duration(milliseconds: 280);

  /// Profile body cross-fade, sheet open.
  static const Duration gentle = Duration(milliseconds: 420);

  /// Splash, match-success, premium banner reveal.
  static const Duration hero = Duration(milliseconds: 640);

  /// Stagger interval between sibling reveals in a list/grid.
  static const Duration staggerStep = Duration(milliseconds: 60);

  /// Shimmer cycle for [QeranSkeleton].
  static const Duration shimmer = Duration(milliseconds: 1400);

  /// [QeranLoader] full rotation cycle.
  static const Duration loaderCycle = Duration(milliseconds: 1600);

  /// One pass of the onboarding privacy blur-reveal seam (it ping-pongs, so a
  /// full cycle is 2×). Deliberately the slowest token in the set — meditative,
  /// not a UI transition. Matches the motion designer's reference exactly
  /// (`docs/_design/Qeran Privacy Seam.html` → `6s ease-in-out alternate`).
  static const Duration revealSweep = Duration(seconds: 6);
}

class QeranCurves {
  const QeranCurves._();

  /// Default — used for fast/standard/gentle.
  static const Curve standard = Curves.easeOutCubic;

  /// Hero — used for the signature scale-in.
  static const Curve hero = Curves.easeOutQuart;

  /// Shimmer — symmetric ease.
  static const Curve shimmer = Curves.easeInOut;

  /// Blur-reveal seam sweep — symmetric ease so the seam eases in and out at
  /// both ends of every ping-pong pass (used as both curve and reverseCurve).
  static const Curve revealSweep = Curves.easeInOut;
}
