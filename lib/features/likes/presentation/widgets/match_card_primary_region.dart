import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';

/// The action region of a Matches-tab card: the primary button, or the widget
/// standing in for it.
///
/// Lifted out of `MatchCardScaffold` whole. The scaffold's job is the vertical
/// rhythm of a card's regions (header, actions, secondary, footer); this is the
/// one region that carries its own reasoning, and it was the reason that file
/// could not take another slot.
///
/// ⚠️ [isEnded] came WITH the region, and that is the point of the split.
/// This region once also held a caption under the button — «ستتواصل معك
/// الخطّابة للتنسيق للقاء الرسمي مع الأهل» — and sub-step 7b guarded the
/// button without it, because it was a SEPARATE `if`. The card withdrew the
/// action and left the caption promising a meeting nobody was arranging.
///
/// The caption has since been removed outright, so that particular bug can no
/// longer recur. The structure it argued for is kept deliberately: anything
/// added here is inside the guard by construction rather than by remembering,
/// which is the half of the lesson that outlives the string.
class MatchCardPrimaryRegion extends StatelessWidget {
  const MatchCardPrimaryRegion({
    super.key,
    this.primaryLabel,
    this.onPrimaryPressed,
    this.primaryLoading = false,
    this.primaryTrailingIcon,
    this.primaryVariant = QeranButtonVariant.primaryWine,
    this.primaryOverride,
    this.isEnded = false,
  });

  final String? primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final bool primaryLoading;
  final IconData? primaryTrailingIcon;
  final QeranButtonVariant primaryVariant;

  /// Rendered INSTEAD of the single [primaryLabel] button — the responder
  /// states use it to place a pair the one slot cannot express.
  final Widget? primaryOverride;

  /// Whether the compatibility journey has stopped. Everything here is
  /// withdrawn together — see the class doc.
  final bool isEnded;

  @override
  Widget build(BuildContext context) {
    if (isEnded) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (primaryOverride != null) ...[
          const SizedBox(height: QeranSpacing.s12),
          primaryOverride!,
        ] else if (primaryLabel != null) ...[
          const SizedBox(height: QeranSpacing.s12),
          QeranButton(
            label: primaryLabel!,
            onPressed: onPrimaryPressed,
            variant: primaryVariant,
            size: QeranButtonSize.xs,
            loading: primaryLoading,
            trailingIcon: primaryTrailingIcon,
          ),
        ],
      ],
    );
  }
}
