import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import '../theme/app_color.dart';

class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    this.fillColor,
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.keyboardType,
    this.textInputAction,
    this.suffixIcon,
    this.onTap,
    this.prefixIcon,
    this.validator,
    this.focusNode,
    this.errorMsg,
    this.onChange,
    this.border,
    this.borderRadius = QeranRadii.dome,
    this.maxLines = 1,
    this.maxLength,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final String? errorMsg;
  final Color? fillColor;
  final OutlineInputBorder? border;
  final void Function(String)? onChange;
  final TextInputAction? textInputAction;

  /// Corner radius for the field's enabled/focused borders. Defaults to the
  /// unified [QeranRadii.dome] so every field shares the brand's soft-stadium
  /// shape; override only when a specific surface needs a different radius.
  final double borderRadius;

  /// Visible line count. Defaults to `1` (single-line) so every existing
  /// call site is unchanged; the matchmaker reject sheet passes `5`.
  final int maxLines;

  /// Optional character cap (shows the built-in counter). `null` = no
  /// limit, matching all pre-existing call sites.
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      focusNode: focusNode,
      onTap: onTap,
      onChanged: onChange,
      autofocus: false,
      textInputAction: textInputAction ?? TextInputAction.next,
      decoration: InputDecoration(
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        border: border,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: AppColors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        fillColor: fillColor ?? AppColors.fieldBackground,
        filled: true,
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.grey),
        errorText: errorMsg,
      ),
    );
  }
}
