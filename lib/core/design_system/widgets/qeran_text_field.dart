import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_radii.dart';
import '../tokens/qeran_shadows.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';

/// Brand text field — the design-system input (it superseded the former
/// legacy `AppTextFormField`). Wraps a [TextFormField] so `Form.validate()` keeps
/// working, paints only from tokens (paper fill, borderless pill resting on a
/// soft [QeranShadows.e1] lift, wine-tinted neutrals, danger ring only on
/// error), and mirrors with the locale (`EdgeInsetsDirectional`, no manual
/// RTL swap).
///
/// Stateful because it owns the password-visibility state for the built-in
/// eye ([showObscureToggle]) and disposes an internally-created [FocusNode]
/// when the caller doesn't supply one.
class QeranTextField extends StatefulWidget {
  const QeranTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.validator,
    this.errorText,
    this.obscureText = false,
    this.showObscureToggle = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.enabled = true,
    this.readOnly = false,
    this.maxLength,
    this.maxLines = 1,
    this.prefix,
    this.suffix,
    this.autofillHints,
  });

  final TextEditingController controller;

  /// Optional static label rendered above the field (start-aligned).
  final String? label;
  final String? hint;
  final FormFieldValidator<String>? validator;

  /// Explicit error (e.g. a server-side message) shown beneath the field,
  /// independent of [validator].
  final String? errorText;

  /// Whether the field hides input. Pair with [showObscureToggle] for a
  /// built-in eye; leave the toggle off to keep the field permanently masked.
  final bool obscureText;

  /// When `true` (and [obscureText] is `true`), renders a built-in eye that
  /// flips visibility — the field owns that state, so call sites don't.
  final bool showObscureToggle;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool enabled;
  final bool readOnly;
  final int? maxLength;
  final int maxLines;

  /// Arbitrary leading widget — an icon, or a richer control like the
  /// country-code picker for the phone field.
  final Widget? prefix;

  /// Arbitrary trailing widget. Ignored when [showObscureToggle] is on (the
  /// built-in eye takes the slot).
  final Widget? suffix;
  final Iterable<String>? autofillHints;

  @override
  State<QeranTextField> createState() => _QeranTextFieldState();
}

class _QeranTextFieldState extends State<QeranTextField> {
  FocusNode? _internalFocusNode;
  late bool _obscured;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant QeranTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscured = widget.obscureText;
    }
  }

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _toggleObscure() => setState(() => _obscured = !_obscured);

  /// Pill for single-line; a softer [QeranRadii.controlR] for multiline text
  /// areas (a stadium looks wrong on a tall box). Obscured input is always
  /// single-line, so it stays a pill regardless of [QeranTextField.maxLines].
  BorderRadius get _radius => (widget.maxLines > 1 && !widget.obscureText)
      ? QeranRadii.controlR
      : QeranRadii.pill;

  @override
  Widget build(BuildContext context) {
    final field = _buildField();
    if (widget.label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label!,
          style: QeranTypography.bodySm.copyWith(color: QeranColors.inkBody),
        ),
        QeranSpacing.vs8,
        field,
      ],
    );
  }

  Widget _buildField() {
    // The pill + soft lift live on the wrapper so the shadow follows the
    // rounded box; the field itself is borderless (Figma: floating white
    // pills, no outline). A danger ring appears only on validation error.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _radius,
        boxShadow: QeranShadows.e1,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        validator: widget.validator,
        obscureText: widget.obscureText && _obscured,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        onTap: widget.onTap,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        maxLength: widget.maxLength,
        // Obscured input must stay single-line.
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        autofillHints: widget.autofillHints,
        cursorColor: QeranColors.wine,
        style: QeranTypography.body.copyWith(color: QeranColors.inkStrong),
        decoration: _decoration(),
      ),
    );
  }

  InputDecoration _decoration() {
    return InputDecoration(
      filled: true,
      fillColor: QeranColors.paper,
      contentPadding: const EdgeInsetsDirectional.fromSTEB(
        QeranSpacing.s20,
        QeranSpacing.s16,
        QeranSpacing.s20,
        QeranSpacing.s16,
      ),
      hintText: widget.hint,
      hintStyle: QeranTypography.bodySm.copyWith(color: QeranColors.inkFaint),
      errorText: widget.errorText,
      errorStyle: QeranTypography.caption.copyWith(color: QeranColors.danger),
      counterStyle:
          QeranTypography.caption.copyWith(color: QeranColors.inkMuted),
      prefixIcon: widget.prefix,
      suffixIcon: _suffix(),
      // Borderless at rest/focus; the wrapper's shadow defines the field.
      enabledBorder: _border(),
      focusedBorder: _border(),
      disabledBorder: _border(),
      errorBorder: _border(const BorderSide(color: QeranColors.danger)),
      focusedErrorBorder:
          _border(const BorderSide(color: QeranColors.danger, width: 1.5)),
    );
  }

  Widget? _suffix() {
    if (widget.obscureText && widget.showObscureToggle) {
      return IconButton(
        onPressed: _toggleObscure,
        icon: Icon(
          _obscured
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: QeranColors.inkFaint,
        ),
      );
    }
    return widget.suffix;
  }

  OutlineInputBorder _border([BorderSide side = BorderSide.none]) {
    return OutlineInputBorder(
      borderRadius: _radius,
      borderSide: side,
    );
  }
}
