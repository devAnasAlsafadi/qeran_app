import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/core/widgets/app_button.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class OathFooter extends StatelessWidget {
  final bool isChecked;
  final VoidCallback onSwear;

  const OathFooter({
    super.key,
    required this.isChecked,
    required this.onSwear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          LocaleKeys.auth_oath_footer.t(context),
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: AppDimens.p24),
        // `CustomButton.disabledBackgroundColor` is the supplied
        // `backgroundColor` at 60 % alpha. Always passing burgundy keeps
        // the disabled state on-brand (faded plum) instead of generic
        // grey, while `onPressed: null` still gates interactivity.
        CustomButton(
          text: LocaleKeys.auth_oath_button.t(context),
          backgroundColor: AppColors.primary,
          onPressed: isChecked ? onSwear : null,
        ),
        const SizedBox(height: AppDimens.p24),
      ],
    );
  }
}
