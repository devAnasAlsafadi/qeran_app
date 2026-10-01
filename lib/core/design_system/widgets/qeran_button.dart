import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_motion.dart';
import '../tokens/qeran_radii.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';
import 'qeran_loader.dart';

part 'qeran_button_parts.dart';

enum QeranButtonVariant {
  primary,
  primaryGold,
  primaryWine,
  secondary,
  ghost,
  neutral,
  destructive,
}

/// Heights: lg 54 · md 46 · compact 48 · xs 40 · sm 36.
///
/// [compact] is the dense-row size: the label type and tight padding long
/// Arabic labels need, at the full 48 pt tap target. [xs] is the same at 40 pt,
/// kept by the matchmaker app until its tap-target sweep (Phase 4).
enum QeranButtonSize { lg, md, sm, xs, compact }

class QeranButton extends StatelessWidget {
  const QeranButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = QeranButtonVariant.primary,
    this.size = QeranButtonSize.lg,
    this.leadingIcon,
    this.trailingIcon,
    this.fullWidth = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final QeranButtonVariant variant;
  final QeranButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool fullWidth;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final spec = _spec(variant);
    final h = _height(size);
    final hPad = _hPad(size);
    final disabled = onPressed == null || loading;

    final child = loading
        ? QeranLoader(
            size: 18,
            strokeWidth: 2.2,
            primary: spec.loaderPrimary ?? spec.fg,
            accent: spec.loaderAccent ?? spec.fg,
          )
        : _Content(
            label: label,
            color: spec.fg,
            leadingIcon: leadingIcon,
            trailingIcon: trailingIcon,
            size: size,
          );

    return AnimatedOpacity(
      duration: QeranMotion.fast,
      opacity: disabled && !loading ? 0.5 : 1.0,
      child: SizedBox(
        height: h,
        width: fullWidth ? double.infinity : null,
        child: Material(
          color: spec.bg,
          shape: RoundedRectangleBorder(
            borderRadius: QeranRadii.controlR,
            side: spec.border == null
                ? BorderSide.none
                : BorderSide(color: spec.border!, width: 1.5),
          ),
          child: InkWell(
            borderRadius: QeranRadii.controlR,
            onTap: disabled ? null : onPressed,
            splashColor: spec.fg.withValues(alpha: 0.08),
            highlightColor: spec.fg.withValues(alpha: 0.04),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }

  static double _height(QeranButtonSize s) => switch (s) {
        QeranButtonSize.lg => 54,
        QeranButtonSize.md => 46,
        QeranButtonSize.sm => 36,
        // Compact: dense two-button rows where labels need the width.
        QeranButtonSize.xs => 40,
        // The same, at the full 48 pt tap target.
        QeranButtonSize.compact => 48,
      };

  static double _hPad(QeranButtonSize s) => switch (s) {
        QeranButtonSize.lg => QeranSpacing.s24,
        QeranButtonSize.md => QeranSpacing.s20,
        QeranButtonSize.sm => QeranSpacing.s16,
        // Tight horizontal padding so long Arabic labels stay on one line.
        QeranButtonSize.xs || QeranButtonSize.compact => QeranSpacing.s8,
      };

  static _Spec _spec(QeranButtonVariant v) => switch (v) {
        QeranButtonVariant.primary => const _Spec(
            bg: QeranColors.gold,
            fg: QeranColors.wine,
            // On gold, wine carries the motion and the deeper gold gives the
            // second arc without fighting the fill.
            loaderPrimary: QeranColors.wine,
            loaderAccent: QeranColors.goldDeep,
          ),
        // Solid gold with white label — pairs with [primaryWine] in the
        // two-button match rows. Uses [goldDeep] (not the light brand
        // gold) so white text stays legible.
        QeranButtonVariant.primaryGold => const _Spec(
            bg: QeranColors.goldDeep,
            fg: QeranColors.paper,
            loaderPrimary: QeranColors.paper,
            loaderAccent: QeranColors.wine,
          ),
        // The login CTA. Wine-on-wine would be an invisible arc, so the brand
        // pair reads as gold + paper here — the dual-arc motion survives,
        // which is the point of the branded loader.
        QeranButtonVariant.primaryWine => const _Spec(
            bg: QeranColors.wine,
            fg: QeranColors.paper,
            loaderPrimary: QeranColors.gold,
            loaderAccent: QeranColors.paper,
          ),
        // Light fills — the canonical wine + gold pair.
        QeranButtonVariant.secondary => const _Spec(
            bg: Colors.transparent,
            fg: QeranColors.wine,
            border: QeranColors.wine,
            loaderPrimary: QeranColors.wine,
            loaderAccent: QeranColors.goldDeep,
          ),
        QeranButtonVariant.ghost => const _Spec(
            bg: Colors.transparent,
            fg: QeranColors.wine,
            loaderPrimary: QeranColors.wine,
            loaderAccent: QeranColors.goldDeep,
          ),
        // Soft wine-tinted "chip" fill — the matchmaker card's secondary
        // action buttons (a modern soft neutral, never cold grey).
        QeranButtonVariant.neutral => const _Spec(
            bg: QeranColors.softFill,
            fg: QeranColors.wine,
            loaderPrimary: QeranColors.wine,
            loaderAccent: QeranColors.goldDeep,
          ),
        QeranButtonVariant.destructive => const _Spec(
            bg: Colors.transparent,
            fg: QeranColors.danger,
            border: QeranColors.danger,
          ),
      };
}
