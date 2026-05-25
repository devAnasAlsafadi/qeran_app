import 'package:flutter/material.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/app_text_style.dart';

class AuthTitleSubtitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextAlign textAlign;

  const AuthTitleSubtitle({
    super.key,
    required this.title,
    this.subtitle,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppTextStyles.headlineMedium, textAlign: textAlign),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: textAlign,
          ),
        ],
      ],
    );
  }
}
