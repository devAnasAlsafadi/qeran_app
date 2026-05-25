import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_motion.dart';
import '../tokens/qeran_radii.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';
import 'qeran_loader.dart';

enum QeranButtonVariant { primary, primaryWine, secondary, ghost, destructive }

enum QeranButtonSize { lg, md, sm }

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
        ? QeranLoader.inline(color: spec.fg)
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
      };

  static double _hPad(QeranButtonSize s) => switch (s) {
        QeranButtonSize.lg => QeranSpacing.s24,
        QeranButtonSize.md => QeranSpacing.s20,
        QeranButtonSize.sm => QeranSpacing.s16,
      };

  static _Spec _spec(QeranButtonVariant v) => switch (v) {
        QeranButtonVariant.primary => const _Spec(
            bg: QeranColors.gold,
            fg: QeranColors.wine,
          ),
        QeranButtonVariant.primaryWine => const _Spec(
            bg: QeranColors.wine,
            fg: QeranColors.paper,
          ),
        QeranButtonVariant.secondary => const _Spec(
            bg: Colors.transparent,
            fg: QeranColors.wine,
            border: QeranColors.wine,
          ),
        QeranButtonVariant.ghost => const _Spec(
            bg: Colors.transparent,
            fg: QeranColors.wine,
          ),
        QeranButtonVariant.destructive => const _Spec(
            bg: Colors.transparent,
            fg: QeranColors.danger,
            border: QeranColors.danger,
          ),
      };
}

class _Spec {
  const _Spec({required this.bg, required this.fg, this.border});
  final Color bg;
  final Color fg;
  final Color? border;
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
    final style = (size == QeranButtonSize.sm
            ? QeranTypography.label
            : QeranTypography.subtitle)
        .copyWith(color: color);
    final iconSize = size == QeranButtonSize.sm ? 16.0 : 18.0;

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
