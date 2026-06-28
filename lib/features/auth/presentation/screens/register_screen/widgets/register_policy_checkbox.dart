import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class RegisterPolicyCheckbox extends StatelessWidget {
  final ValueNotifier<bool> acceptedPolicyNotifier;
  final VoidCallback onToggleAcceptance;

  const RegisterPolicyCheckbox({
    super.key,
    required this.acceptedPolicyNotifier,
    required this.onToggleAcceptance,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: acceptedPolicyNotifier,
      builder: (context, acceptedPolicy, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            RichText(
              text: TextSpan(
                style: QeranTypography.caption.copyWith(
                  color: QeranColors.inkMuted,
                ),
                children: [
                  TextSpan(text: LocaleKeys.auth_policy_agree.t(context)),
                  TextSpan(
                    text: LocaleKeys.auth_privacy_policy.t(context),
                    style: QeranTypography.caption.copyWith(
                      color: QeranColors.gold,
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.9,
              child: Checkbox(
                value: acceptedPolicy,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (_) => onToggleAcceptance(),
              ),
            ),
          ],
        );
      },
    );
  }
}
