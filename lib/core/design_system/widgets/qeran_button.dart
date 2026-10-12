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

/// Heights: lg 54 · md 48 · compact 48 — each a minimum. A label never cuts
/// and its font never shrinks: one too wide for its slot wraps onto a second
/// line and the button grows (run 6). Side by side, `QeranButtonRow` keeps the
/// pair at one height.
///
/// [compact] is the dense-row size: the label type and tight padding long
/// Arabic labels need, at the full 48 pt tap target. The 40 pt `xs` and 36 pt
/// `sm` it replaced are gone (Phase 4 D1, Q11), so nothing can pick them again.
enum QeranButtonSize { lg, md, compact }

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

  /// Fills the width it's given. Without it the button is as wide as its
  /// label wherever it sits — a column, a wrap, an Align — and never
  /// narrower than [minTapWidth].
  final bool fullWidth;
  final bool loading;

  /// The narrowest a button that hugs its label gets: the tap target.
  static const double minTapWidth = 48;

  @override
  Widget build(BuildContext context) {
    final spec = _specOf(variant);
    final disabled = onPressed == null || loading;
    return AnimatedOpacity(
      duration: QeranMotion.fast,
      opacity: disabled && !loading ? 0.5 : 1.0,
      child: SizedBox(
        width: fullWidth ? double.infinity : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minTapWidth,
            minHeight: _height(size),
          ),
          child: _surface(spec, disabled: disabled),
        ),
      ),
    );
  }

  Widget _surface(_Spec spec, {required bool disabled}) => Material(
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
        padding: EdgeInsets.symmetric(
          horizontal: _hPad(size),
          vertical: QeranSpacing.s8,
        ),
        // A width factor of 1 sizes the button to its label instead of
        // filling whatever width it's given; a height factor of 1 keeps it to
        // its label's lines, never the height of whatever holds it.
        child: Center(
          widthFactor: fullWidth ? null : 1,
          heightFactor: 1,
          child: _child(spec),
        ),
      ),
    ),
  );

  /// The label — or, loading, the loader over the label's room: the button
  /// keeps its width and its lines while it loads, so nothing around it
  /// moves.
  Widget _child(_Spec spec) {
    final content = _Content(
      label: label,
      color: spec.fg,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      size: size,
    );
    if (!loading) return content;
    final loader = QeranLoader(
      size: 18,
      strokeWidth: 2.2,
      primary: spec.loaderPrimary ?? spec.fg,
      accent: spec.loaderAccent ?? spec.fg,
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        Visibility.maintain(visible: false, child: content),
        loader,
      ],
    );
  }

  static double _height(QeranButtonSize s) => switch (s) {
        QeranButtonSize.lg => 54,
        QeranButtonSize.md => 48,
        // Dense rows where labels need the width, at the full 48 pt target.
        QeranButtonSize.compact => 48,
      };

  static double _hPad(QeranButtonSize s) => switch (s) {
        QeranButtonSize.lg => QeranSpacing.s24,
        QeranButtonSize.md => QeranSpacing.s20,
        // Tight horizontal padding so long Arabic labels stay on one line.
        QeranButtonSize.compact => QeranSpacing.s8,
      };
}
