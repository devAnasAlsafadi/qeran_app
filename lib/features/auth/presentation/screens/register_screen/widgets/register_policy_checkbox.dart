import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_motion.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Registration agreement row — a DS-native oath check (no Material
/// `Checkbox`): a 20×20 box that fills gold with a wine check when accepted,
/// leading the policy sentence with its wine-bold link. The whole row is
/// tappable. Logic identical — a single toggle callback fires.
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
        return GestureDetector(
          onTap: onToggleAcceptance,
          behavior: HitTestBehavior.opaque,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OathBox(checked: acceptedPolicy),
              QeranSpacing.hs12,
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: QeranTypography.bodySm.copyWith(
                      color: QeranColors.inkBody,
                    ),
                    children: [
                      TextSpan(text: LocaleKeys.auth_policy_agree.t(context)),
                      TextSpan(
                        text: LocaleKeys.auth_privacy_policy.t(context),
                        style: QeranTypography.bodySm.copyWith(
                          color: QeranColors.wine,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OathBox extends StatelessWidget {
  final bool checked;

  const _OathBox({required this.checked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: QeranMotion.fast,
      curve: QeranCurves.standard,
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: checked ? QeranColors.gold : null,
        borderRadius: QeranRadii.xsR,
        border: checked
            ? null
            : Border.all(color: QeranColors.wine40, width: 1.5),
      ),
      child: checked
          ? const Icon(Icons.check_rounded, size: 15, color: QeranColors.wine)
          : null,
    );
  }
}
