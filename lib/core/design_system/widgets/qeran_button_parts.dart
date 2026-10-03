part of 'qeran_button.dart';

class _Spec {
  const _Spec({
    required this.bg,
    required this.fg,
    this.border,
    this.loaderPrimary,
    this.loaderAccent,
  });
  final Color bg;
  final Color fg;
  final Color? border;

  /// The two arc colours of the in-button [QeranLoader]. Both must read
  /// against [bg], which is why they are per-variant rather than a single
  /// foreground: the brand's wine arc is invisible on a wine button, so that
  /// variant pairs gold with paper instead. Null on either falls back to [fg],
  /// giving a monochrome spinner where a second colour would only muddle the
  /// signal (destructive).
  final Color? loaderPrimary;
  final Color? loaderAccent;
}

/// Each variant's fill, label colour, border and loader arcs.
_Spec _specOf(QeranButtonVariant v) => switch (v) {
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

class _Content extends StatelessWidget {
  const _Content({
    required this.label,
    required this.color,
    required this.size,
    this.leadingIcon,
    this.trailingIcon,
  });

  final String label;
  final Color color;
  final QeranButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final compact = switch (size) {
      QeranButtonSize.lg || QeranButtonSize.md => false,
      QeranButtonSize.compact || QeranButtonSize.sm || QeranButtonSize.xs =>
        true,
    };
    final style = (compact ? QeranTypography.label : QeranTypography.subtitle)
        .copyWith(color: color);
    final iconSize = compact ? 16.0 : 18.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: iconSize, color: color),
          QeranSpacing.hs8,
        ],
        Flexible(
          child: Text(
            label,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingIcon != null) ...[
          QeranSpacing.hs8,
          Icon(trailingIcon, size: iconSize, color: color),
        ],
      ],
    );
  }
}
