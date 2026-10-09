import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

/// Four faint post-shaped cards behind the community slide's card — the feed
/// glimpsed past it. Two hug the hero's top and two its bottom, so they frame
/// the card at any height; each sits at a start or end edge, so they mirror
/// with the language. Sizes and offsets are the board's (a 412-wide frame).
///
/// Decoration only: fill this over the hero with `Positioned.fill`.
class OnboardingGhostCards extends StatelessWidget {
  const OnboardingGhostCards({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PositionedDirectional(
            top: 44,
            start: -20,
            child: _Ghost(width: 150, height: 44),
          ),
          PositionedDirectional(
            top: 108,
            end: 22,
            child: _Ghost(width: 180, height: 44),
          ),
          PositionedDirectional(
            bottom: 20,
            start: 20,
            child: _Ghost(width: 200, height: 40),
          ),
          PositionedDirectional(
            bottom: -6,
            end: 22,
            child: _Ghost(width: 140, height: 36),
          ),
        ],
      ),
    );
  }
}

/// One ghost: a wine-light tile with two gold-12 lines standing in for text.
class _Ghost extends StatelessWidget {
  final double width;
  final double height;

  const _Ghost({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: QeranSpacing.s12,
        vertical: QeranSpacing.s8,
      ),
      decoration: const BoxDecoration(
        color: QeranColors.wineLight,
        borderRadius: QeranRadii.controlR,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Line(widthFactor: 0.7),
          SizedBox(height: QeranSpacing.s6),
          _Line(widthFactor: 0.45),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final double widthFactor;

  const _Line({required this.widthFactor});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: const SizedBox(
        height: 6,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: QeranColors.gold12,
            borderRadius: QeranRadii.pill,
          ),
        ),
      ),
    );
  }
}
