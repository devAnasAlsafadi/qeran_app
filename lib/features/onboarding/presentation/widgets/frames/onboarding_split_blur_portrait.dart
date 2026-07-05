import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/utils/app_assets.dart';

/// The privacy portrait with a **diagonal split blur**: a clear photo on the
/// lower-left half that dissolves through a soft feathered seam into a frosted
/// (blurred + wine-veiled) upper-right half — a literal demo of the app's
/// gradual-unblur mechanic. A wine gradient backs the portrait's transparent
/// corners.
///
/// The frost is an [ImageFiltered] copy (not a hard-clipped `BackdropFilter`)
/// so the seam can feather; a [ShaderMask] fades it out across the diagonal.
class OnboardingSplitBlurPortrait extends StatelessWidget {
  const OnboardingSplitBlurPortrait({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Wine base — tints the portrait and backs its transparent corners.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [QeranColors.wine, QeranColors.wineLight],
            ),
          ),
        ),
        // The clear portrait.
        Image.asset(AppAssets.female, fit: BoxFit.cover),
        // The frosted half, masked to a feathered diagonal so it dissolves into
        // the clear half instead of meeting it at a hard edge.
        ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: const [0.0, 0.46, 0.66],
            colors: [
              QeranColors.paper,
              QeranColors.paper,
              QeranColors.paper.withValues(alpha: 0),
            ],
          ).createShader(rect),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Image.asset(AppAssets.female, fit: BoxFit.cover),
              ),
              const ColoredBox(color: QeranColors.wine20),
            ],
          ),
        ),
      ],
    );
  }
}
