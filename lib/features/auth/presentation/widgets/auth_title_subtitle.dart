import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

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
        Text(title, style: QeranTypography.headline, textAlign: textAlign),
        if (subtitle != null) ...[
          QeranSpacing.vs8,
          Text(
            subtitle!,
            style: QeranTypography.body.copyWith(color: QeranColors.inkMuted),
            textAlign: textAlign,
          ),
        ],
      ],
    );
  }
}
