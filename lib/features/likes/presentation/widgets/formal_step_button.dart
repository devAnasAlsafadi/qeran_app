import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Full-width "خطوة رسمية عبر الخطّابة" CTA shared by match stages 1 & 2.
/// Shows a loader while the partner card is being shared, and a check
/// once sent — a repeat tap then just re-opens the chat (the cubit
/// guards against re-posting the card).
class FormalStepButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool sending;
  final bool sent;

  const FormalStepButton({
    super.key,
    required this.onTap,
    required this.sending,
    required this.sent,
  });

  @override
  Widget build(BuildContext context) {
    return QeranButton(
      label: LocaleKeys.likes_matches_formal_step_cta.t(context),
      onPressed: onTap,
      variant: QeranButtonVariant.primaryWine,
      size: QeranButtonSize.xs,
      loading: sending,
      trailingIcon: sent ? Icons.check_rounded : null,
    );
  }
}
