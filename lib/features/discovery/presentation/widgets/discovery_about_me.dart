import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';

/// Card-body section: header (server-supplied Arabic label) + free text.
class DiscoveryAboutMe extends StatelessWidget {
  final String header;
  final String text;

  /// Max number of lines for the body text. Defaults to 3 so a typical
  /// long bio truncates with ellipsis on the card; the details sheet
  /// shows the full text.
  final int maxLines;

  const DiscoveryAboutMe({
    super.key,
    required this.header,
    required this.text,
    this.maxLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.person_outline_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppDimens.p4 + 2),
            Text(
              header,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.p8),
        Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            height: 1.55,
          ),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
