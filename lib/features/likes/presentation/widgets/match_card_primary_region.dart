import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';

/// The action region of a Matches-tab card: the primary button — or the widget
/// standing in for it — and the helper line that captions it.
///
/// Lifted out of `MatchCardScaffold` whole. The scaffold's job is the vertical
/// rhythm of a card's regions (header, actions, secondary, footer); this is the
/// one region that carries its own reasoning, and it was the reason that file
/// could not take another slot.
///
/// ⚠️ [isEnded] came WITH the region, and that is the point of the split.
/// Sub-step 7b guarded the button but not the helper — a SEPARATE `if`, as it
/// has to be, since the responder state has buttons and no helper — and the
/// card withdrew the action while its caption went on promising a meeting
/// nobody was arranging. Holding both inside one widget makes the next thing
/// added here guarded by construction rather than by remembering.
class MatchCardPrimaryRegion extends StatelessWidget {
  const MatchCardPrimaryRegion({
    super.key,
    this.primaryLabel,
    this.onPrimaryPressed,
    this.primaryLoading = false,
    this.primaryTrailingIcon,
    this.primaryVariant = QeranButtonVariant.primaryWine,
    this.primaryOverride,
    this.primaryHelperText,
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

  /// What pressing the primary button actually sets in motion. Null in the
  /// responder states: a line describing one button becomes a caption for both
  /// once there are two.
  final String? primaryHelperText;

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
        if (primaryHelperText != null) ...[
          const SizedBox(height: QeranSpacing.s6),
          Text(
            primaryHelperText!,
            textAlign: TextAlign.start,
            style: QeranTypography.caption.copyWith(color: QeranColors.inkBody),
          ),
        ],
      ],
    );
  }
}
