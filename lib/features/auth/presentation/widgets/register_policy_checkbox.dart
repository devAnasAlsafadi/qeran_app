import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';

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
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                children: [
                  const TextSpan(text: 'موافق على '),
                  TextSpan(
                    text: 'سياسات الخصوصية',
                    style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight),
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
