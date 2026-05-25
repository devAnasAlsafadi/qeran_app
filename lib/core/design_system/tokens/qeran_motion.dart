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
}

class QeranCurves {
  const QeranCurves._();

  /// Default — used for fast/standard/gentle.
  static const Curve standard = Curves.easeOutCubic;

  /// Hero — used for the signature scale-in.
  static const Curve hero = Curves.easeOutQuart;

  /// Shimmer — symmetric ease.
  static const Curve shimmer = Curves.easeInOut;
}
