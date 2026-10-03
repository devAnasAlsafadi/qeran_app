import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../generated/locale_keys.g.dart';

/// «تعذّر تحميل المزيد.» and its retry, on one line: where the next page of
/// posts (B9), of comments or of a comment's replies failed. Centred by
/// default; a thread's replies line it up at their own start.
class CommunityPageError extends StatelessWidget {
  const CommunityPageError({
    super.key,
    required this.onRetry,
    this.padding = const EdgeInsets.symmetric(horizontal: QeranSpacing.s16),
    this.alignment = MainAxisAlignment.center,
  });

  final VoidCallback onRetry;
  final EdgeInsetsGeometry padding;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      // One line: a long message wraps in its own space, beside the button.
      child: Row(
        mainAxisAlignment: alignment,
        children: [
          Flexible(
            child: Text(
              LocaleKeys.community_feed_page_error.t(context),
              style: QeranTypography.bodySm.copyWith(
                color: QeranColors.inkMuted,
              ),
            ),
          ),
          QeranSpacing.hs4,
          QeranButton(
            label: LocaleKeys.community_feed_retry.t(context),
            onPressed: onRetry,
            variant: QeranButtonVariant.ghost,
            size: QeranButtonSize.compact,
            leadingIcon: Icons.refresh_rounded,
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}
