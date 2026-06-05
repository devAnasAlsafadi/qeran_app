import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

class OtpInputRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;

  const OtpInputRow({
    super.key,
    required this.controllers,
    required this.focusNodes,
  });

  @override
  Widget build(BuildContext context) {
    // OTP codes read left-to-right in every locale, so the boxes stay LTR
    // (first box on the left) even in Arabic. Scoped to this Row via its own
    // textDirection — not the forbidden Directionality widget (DESIGN.md §6).
    return Row(
      textDirection: TextDirection.ltr,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(controllers.length, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s8),
          child: _OtpBox(
            controller: controllers[index],
            focusNode: focusNodes[index],
            onChanged: (value) {
              if (value.isNotEmpty && index < controllers.length - 1) {
                FocusScope.of(context).requestFocus(focusNodes[index + 1]);
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).requestFocus(focusNodes[index - 1]);
              }
            },
          ),
        );
      }),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 55,
      height: 65,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        style: QeranTypography.headline,
        decoration: const InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: QeranRadii.controlR,
            borderSide: BorderSide(color: QeranColors.hairline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: QeranRadii.controlR,
            borderSide: BorderSide(
              color: QeranColors.wine,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: QeranColors.paper,
        ),
      ),
    );
  }
}
