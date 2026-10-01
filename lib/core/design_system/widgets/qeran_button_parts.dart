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
    final compact =
        size == QeranButtonSize.sm || size == QeranButtonSize.xs;
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
