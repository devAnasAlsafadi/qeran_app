import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/utils/app_assets.dart';

/// The privacy portrait — a sample profile whose photo carries a **baked-in
/// vertical split** from frosted to clear, a literal demo of the app's
/// gradual-unblur mechanic. Shown full-bleed (`cover`); the card's centred gold
/// seam lines up with the portrait's midline. A wine base backs it while the
/// asset loads.
class OnboardingSplitBlurPortrait extends StatelessWidget {
  const OnboardingSplitBlurPortrait({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: QeranColors.wine,
      child: SizedBox.expand(
        child: Image(
          image: AssetImage(AppAssets.essencePortrait),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
