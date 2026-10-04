part of 'qeran_text_field.dart';

const _contentPadding = EdgeInsetsDirectional.fromSTEB(
  QeranSpacing.s20,
  QeranSpacing.s16,
  QeranSpacing.s20,
  QeranSpacing.s16,
);

const _errorEdge = BorderSide(color: QeranColors.danger);
const _focusedErrorEdge = BorderSide(color: QeranColors.danger, width: 1.5);

/// The field itself and its decoration — kept here so the widget's file
/// holds its parameters and lifecycle.
extension _Field on _QeranTextFieldState {
  Widget _buildField() {
    // The pill + soft lift live on the wrapper so the shadow follows the
    // rounded box; the field itself is borderless (Figma: floating white
    // pills, no outline). A danger ring appears only on validation error.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _radius,
        boxShadow: QeranShadows.e1,
      ),
      child: _formField(),
    );
  }

  TextFormField _formField() {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      validator: widget.validator,
      errorBuilder: widget.helper == null
          ? null
          : (_, error) => QeranHelperLine.error(error),
      obscureText: widget.obscureText && _obscured,
      keyboardType: widget.keyboardType,
      textInputAction: _inputAction,
      onChanged: widget.onChanged,
      onFieldSubmitted: _onSubmitted,
      onTap: widget.onTap,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      maxLength: widget.maxLength,
      // Obscured input must stay single-line.
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      // Dropped alongside it: a resting height above the forced ceiling of 1
      // would trip the framework's own `maxLines >= minLines` assert.
      minLines: widget.obscureText ? null : widget.minLines,
      autofillHints: widget.autofillHints,
      cursorColor: QeranColors.wine,
      style: QeranTypography.body.copyWith(color: QeranColors.inkStrong),
      decoration: _decoration(),
    );
  }

  /// QER-10: single-line fields get a "done" key by default, and it closes
  /// the keyboard. Multi-line fields are left alone — forcing `done` there
  /// would replace the newline key and make the field impossible to break
  /// lines in.
  TextInputAction? get _inputAction =>
      widget.textInputAction ?? (_isSingleLine ? TextInputAction.done : null);

  void _onSubmitted(String value) {
    widget.onSubmitted?.call(value);
    // Only when the caller has not taken over the action: a field that
    // sets `next` is chaining focus to the following field and must not
    // have the keyboard pulled out from under it.
    if (widget.textInputAction == null && _isSingleLine) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  InputDecoration _decoration() {
    return InputDecoration(
      filled: true,
      fillColor: QeranColors.paper,
      contentPadding: _contentPadding,
      hintText: widget.hint,
      hintStyle: QeranTypography.bodySm.copyWith(color: QeranColors.inkFaint),
      helper: widget.helper,
      // With a help line an error takes its shape: Material allows the
      // widget or the text, never both.
      errorText: widget.helper == null ? widget.errorText : null,
      error: _errorLine(),
      errorStyle: QeranTypography.caption.copyWith(color: QeranColors.danger),
      counterStyle: QeranTypography.caption.copyWith(
        color: QeranColors.inkMuted,
      ),
      prefixIcon: widget.prefix,
      suffixIcon: _suffix(),
      // Borderless at rest/focus; the wrapper's shadow defines the field.
      enabledBorder: _border(),
      focusedBorder: _border(),
      disabledBorder: _border(),
      errorBorder: _border(_errorEdge),
      focusedErrorBorder: _border(_focusedErrorEdge),
    );
  }

  /// [QeranTextField.errorText] as the help line's error, when there's one.
  Widget? _errorLine() => switch (widget.errorText) {
    final error? when widget.helper != null => QeranHelperLine.error(error),
    _ => null,
  };

  Widget? _suffix() {
    if (widget.obscureText && widget.showObscureToggle) {
      return IconButton(
        onPressed: _toggleObscure,
        icon: Icon(
          _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: QeranColors.inkFaint,
        ),
      );
    }
    return widget.suffix;
  }

  OutlineInputBorder _border([BorderSide side = BorderSide.none]) {
    return OutlineInputBorder(borderRadius: _radius, borderSide: side);
  }
}
