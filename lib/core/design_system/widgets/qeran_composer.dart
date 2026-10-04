import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_radii.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';
import 'qeran_loader.dart';

/// A composer's pill-shaped field (chat, Community): paper, a quiet edge
/// that turns wine while focused — or danger while [error] — growing to five
/// lines. [maxLength] is a hard cap when set; without it the text may run
/// past a limit the caller shows itself.
class QeranComposerField extends StatelessWidget {
  const QeranComposerField({
    super.key,
    required this.controller,
    required this.hint,
    this.focusNode,
    this.maxLength,
    this.error = false,
    this.textDirection,
    this.fontFamily,
  });

  final TextEditingController controller;
  final String hint;
  final FocusNode? focusNode;
  final int? maxLength;
  final bool error;

  /// The typed text's own direction and script font, when the caller follows
  /// the text rather than the UI (D13).
  final TextDirection? textDirection;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    final cap = maxLength;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      minLines: 1,
      maxLines: 5,
      maxLength: cap,
      inputFormatters: [if (cap != null) LengthLimitingTextInputFormatter(cap)],
      textInputAction: TextInputAction.newline,
      textDirection: textDirection,
      style: QeranTypography.body.copyWith(
        color: QeranColors.inkStrong,
        fontFamily: fontFamily,
      ),
      decoration: _decoration(),
    );
  }

  InputDecoration _decoration() => InputDecoration(
    filled: true,
    fillColor: QeranColors.paper,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: QeranSpacing.s16,
      vertical: QeranSpacing.s12,
    ),
    hintText: hint,
    hintStyle: QeranTypography.body.copyWith(color: QeranColors.inkMuted),
    counterText: '',
    enabledBorder: _edge(error ? QeranColors.danger : QeranColors.wine08),
    border: _edge(error ? QeranColors.danger : QeranColors.wine08),
    focusedBorder: _edge(error ? QeranColors.danger : QeranColors.wine),
  );

  static OutlineInputBorder _edge(Color color) => OutlineInputBorder(
    borderRadius: QeranRadii.pill,
    borderSide: BorderSide(color: color),
  );
}

/// A composer's round send button: gold while [enabled], faded gold
/// otherwise, and a loader while [sending]. The paper plane mirrors with the
/// locale on its own (`send_rounded` matches the text direction).
class QeranSendButton extends StatelessWidget {
  const QeranSendButton({
    super.key,
    required this.enabled,
    required this.onPressed,
    this.sending = false,
  });

  final bool enabled;
  final VoidCallback onPressed;
  final bool sending;

  static const double size = 44;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled || sending ? QeranColors.gold : QeranColors.gold40,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled && !sending ? onPressed : null,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: sending
                ? const QeranLoader(
                    size: 20,
                    strokeWidth: 2.2,
                    primary: QeranColors.wine,
                    accent: QeranColors.goldDeep,
                  )
                : const Icon(
                    Icons.send_rounded,
                    size: 20,
                    color: QeranColors.wine,
                  ),
          ),
        ),
      ),
    );
  }
}
