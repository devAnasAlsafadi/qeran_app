import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_radii.dart';
import '../tokens/qeran_shadows.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';
import 'qeran_helper_line.dart';

part 'qeran_text_field_parts.dart';

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
    this.minLines,
    this.prefix,
    this.suffix,
    this.autofillHints,
    this.helper,
  }) : assert(
         minLines == null || minLines <= maxLines,
         'minLines cannot exceed maxLines',
       );

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

  /// How many lines the field RESTS at before anything is typed. `null`
  /// (default) keeps every existing call site opening at one line and growing
  /// from there; setting it gives a text area a taller resting box that still
  /// grows to [maxLines] and then scrolls inside itself.
  final int? minLines;

  /// Arbitrary leading widget — an icon, or a richer control like the
  /// country-code picker for the phone field.
  final Widget? prefix;

  /// Arbitrary trailing widget. Ignored when [showObscureToggle] is on (the
  /// built-in eye takes the slot).
  final Widget? suffix;
  final Iterable<String>? autofillHints;

  /// A line of help under the field, beside the counter. A field with one
  /// says what's wrong in the same shape — the error glyph and the text in
  /// danger take the line's place — instead of a bare error text. Both a
  /// [validator]'s message and [errorText] do.
  final QeranHelperLine? helper;

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

  /// Mirrors the `maxLines` the [TextFormField] is actually given — obscured
  /// input is forced single-line regardless of [QeranTextField.maxLines].
  bool get _isSingleLine => widget.obscureText || widget.maxLines == 1;

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
}
