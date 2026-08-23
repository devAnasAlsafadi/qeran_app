import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_strokes.dart';
import 'package:qeran/core/design_system/widgets/qeran_card.dart';

/// The soft-white panel at the base of every onboarding frame.
///
/// Detached from the screen edges — side + bottom margin, all-round corners, a
/// gold hairline and a lift shadow — so it reads as an EXPLANATORY card resting
/// on the wine canvas, not a real app sheet fused to the bottom of the screen.
/// That separation is the whole point: users were opening onboarding and
/// mistaking it for the product.
///
/// Shared by all three frames, which differ only in [topInset] and [child].
/// Every look-bearing property is fixed here on purpose — none is exposed as a
/// parameter, so the three screens cannot drift apart one prop at a time.
/// Margin, border and padding are set below; corner radius (`panelR`), shadow
/// (`e3`) and the paper background come from [QeranCard.hero], so a change to
/// the hero variant moves onboarding with it.
///
/// The panel owns the bottom safe area deliberately: it belongs in the margin
/// (below the card) rather than the padding (inside it), or the two would stack
/// into a double gap and float the card above the gesture bar. Callers pass
/// their own [topInset] only.
class OnboardingExplainerPanel extends StatelessWidget {
  final double topInset;
  final Widget child;

  const OnboardingExplainerPanel({
    super.key,
    required this.topInset,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      // The parent Column centres its children; the panel spans the frame.
      width: double.infinity,
      child: QeranCard.hero(
        // The frames already open with a gold accent bar beside their title.
        accentBar: false,
        // Hairline, not the louder gold/1.5 used on subscription cards.
        border: Border.all(
          color: QeranColors.gold40,
          width: QeranStrokes.hairline,
        ),
        margin: EdgeInsets.fromLTRB(
          QeranSpacing.s16,
          0,
          QeranSpacing.s16,
          safeBottom + QeranSpacing.s16,
        ),
        // Symmetric horizontally, so plain EdgeInsets carries no direction.
        padding: EdgeInsets.fromLTRB(
          QeranSpacing.s20,
          topInset,
          QeranSpacing.s20,
          QeranSpacing.s20,
        ),
        child: child,
      ),
    );
  }
}
