import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import '../../../widgets/auth_email_field.dart';
import '../../../widgets/auth_password_field.dart';
import 'register_policy_checkbox.dart';
import '../register_controller.dart';

class RegisterForm extends StatelessWidget {
  final RegisterController controller;

  const RegisterForm({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QeranTextField(
          controller: controller.nameController,
          focusNode: controller.nameFocus,
          label: LocaleKeys.auth_name_label.t(context),
          hint: LocaleKeys.auth_name_hint.t(context),
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          prefix: const Icon(
            Icons.person_outline_rounded,
            color: QeranColors.inkFaint,
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? LocaleKeys.validators_field_required.t(context)
              : null,
        ),
        QeranSpacing.vs16,
        AuthEmailField(
          controller: controller.emailController,
          focusNode: controller.emailFocus,
          labelText: LocaleKeys.auth_email_label,
          hintText: LocaleKeys.auth_email_hint,
        ),
        QeranSpacing.vs16,
        AuthPasswordField(
          controller: controller.passwordController,
          focusNode: controller.passwordFocus,
          labelText: LocaleKeys.auth_password_label,
        ),
        QeranSpacing.vs16,
        // Optional affiliate referral code — label + "optional" pill, then a
        // label-less field (no validator, so it never blocks Form.validate),
        // with a helper hint beneath.
        Row(
          children: [
            Flexible(
              child: Text(
                LocaleKeys.auth_referral_label.t(context),
                style: QeranTypography.bodySm
                    .copyWith(color: QeranColors.inkBody),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            QeranSpacing.hs8,
            QeranChip(
              label: LocaleKeys.auth_referral_optional.t(context),
              variant: QeranChipVariant.interest,
              compact: true,
            ),
          ],
        ),
        QeranSpacing.vs8,
        QeranTextField(
          controller: controller.referralCodeController,
          focusNode: controller.referralFocus,
          hint: LocaleKeys.auth_referral_placeholder.t(context),
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          prefix: const Icon(
            Icons.redeem_outlined,
            color: QeranColors.inkFaint,
          ),
        ),
        QeranSpacing.vs8,
        Text(
          LocaleKeys.auth_referral_hint.t(context),
          style: QeranTypography.caption.copyWith(color: QeranColors.inkMuted),
        ),
        QeranSpacing.vs20,
        RegisterPolicyCheckbox(
          acceptedPolicyNotifier: controller.acceptedPolicyNotifier,
          onToggleAcceptance: controller.togglePolicyAcceptance,
        ),
      ],
    );
  }
}
