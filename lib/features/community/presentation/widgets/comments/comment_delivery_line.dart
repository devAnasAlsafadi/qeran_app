import 'package:flutter/material.dart';
import 'package:qeran/features/auth/presentation/reader_copy.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../blocs/comments/comment_thread.dart';

/// Under a comment the member sent that isn't settled: «جارٍ النشر…» while
/// it goes (D5), or «لم يُنشر · اضغط لإعادة المحاولة» — the whole line a
/// tap that sends it again (D7).
class CommentDeliveryLine extends StatelessWidget {
  const CommentDeliveryLine({
    super.key,
    required this.delivery,
    required this.onRetry,
  });

  final CommentDelivery delivery;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (delivery) {
      CommentDelivery.pending => SizedBox(
        height: 32,
        child: _Line(
          icon: Icons.schedule_rounded,
          text: LocaleKeys.community_posting.t(context),
          style: QeranTypography.caption,
        ),
      ),
      CommentDelivery.failed => InkWell(
        onTap: onRetry,
        child: SizedBox(
          height: 44,
          child: _Line(
            icon: Icons.error_outline_rounded,
            text: LocaleKeys.community_not_posted
                .forReader(her: LocaleKeys.community_her_not_posted)
                .t(context),
            style: QeranTypography.label.copyWith(color: QeranColors.danger),
          ),
        ),
      ),
    };
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text, required this.style});

  final IconData icon;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: style.color),
        const SizedBox(width: QeranSpacing.s6),
        Flexible(child: Text(text, style: style)),
      ],
    );
  }
}
