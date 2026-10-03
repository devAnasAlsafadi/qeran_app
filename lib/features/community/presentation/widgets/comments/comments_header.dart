import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/utils/compact_count.dart';
import '../../../../../generated/locale_keys.g.dart';

/// «النقاش» above the comments (C1), with the post's count — comments and
/// replies this member can see — once there is one.
class CommentsHeader extends StatelessWidget {
  const CommentsHeader({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s16,
        QeranSpacing.s20,
        QeranSpacing.s4,
      ),
      child: Row(
        children: [
          Text(
            LocaleKeys.community_discussion.t(context),
            style: QeranTypography.subtitle,
          ),
          if (count > 0) ...[
            QeranSpacing.hs8,
            Text(
              formatCompactCount(count, context),
              style: QeranTypography.numeric.copyWith(
                fontSize: QeranTypography.label.fontSize,
                color: QeranColors.inkMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
