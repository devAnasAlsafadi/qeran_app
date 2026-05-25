import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Premium oath card — warm cream→beige gradient surface, soft burgundy
/// shadow, basmala flanked by tiny diamond ornaments, hair-line divider,
/// and the oath body in a calm reading rhythm.
class OathTextBox extends StatelessWidget {
  const OathTextBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.p24,
        AppDimens.p24,
        AppDimens.p24,
        AppDimens.p24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFBF5), Color(0xFFF4E9DC)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F431C33),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const _BasmalaRow(),
          const SizedBox(height: AppDimens.p16),
          _Divider(),
          const SizedBox(height: AppDimens.p16),
          Text(
            LocaleKeys.auth_oath_text.t(context),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              height: 1.9,
              fontSize: 16,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _BasmalaRow extends StatelessWidget {
  const _BasmalaRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.diamond_outlined,
          size: 10,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppDimens.p8),
        Flexible(
          child: Text(
            LocaleKeys.auth_oath_basmala.t(context),
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: AppDimens.p8),
        const Icon(
          Icons.diamond_outlined,
          size: 10,
          color: AppColors.primary,
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.0),
            AppColors.primary.withValues(alpha: 0.25),
            AppColors.primary.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
