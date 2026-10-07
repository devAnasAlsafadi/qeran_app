import 'package:flutter/material.dart';
import 'package:qeran/features/report/presentation/widgets/report_copy.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../domain/entities/community_flag.dart';

/// A reported comment's or reply's frame for the post's author (E1, E2):
/// the gold-12 ground with a 3 pt gold start edge.
const commentFlagDecoration = BoxDecoration(
  color: QeranColors.gold12,
  border: BorderDirectional(
    start: BorderSide(color: QeranColors.gold, width: 3),
  ),
);

/// «تم الإبلاغ · {n} · {reason}» over a reported row (E1, E2): the count in
/// B1 forms and the reason reported most. A reason this build doesn't know
/// leaves the count alone (S18).
class CommentFlagLine extends StatelessWidget {
  const CommentFlagLine({super.key, required this.flag});

  final CommunityFlag flag;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.flag_rounded, size: 16, color: QeranColors.goldDeep),
        const SizedBox(width: QeranSpacing.s6),
        Expanded(
          child: Text(
            _line(context),
            style: QeranTypography.caption.copyWith(
              color: QeranColors.goldDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  String _line(BuildContext context) {
    final count = LocaleKeys.community_flag_reports.tPlural(
      context,
      flag.reportCount,
    );
    final reason = flag.topReason;
    if (reason == null) {
      return LocaleKeys.community_flag_line_count_only.t(
        context,
        namedArgs: {'count': count},
      );
    }
    return LocaleKeys.community_flag_line.t(
      context,
      namedArgs: {
        'count': count,
        'reason': reasonLabelKey(reason, content: true).t(context),
      },
    );
  }
}

/// In place of Like and Reply on a reported row (E1, E2): «إبقاء التعليق» /
/// «إبقاء الرد», and «حذف».
class CommentFlagActions extends StatelessWidget {
  const CommentFlagActions({
    super.key,
    required this.reply,
    required this.onKeep,
    required this.onDelete,
  });

  final bool reply;
  final VoidCallback onKeep;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: QeranSpacing.s8,
        bottom: QeranSpacing.s12,
      ),
      child: Wrap(
        spacing: QeranSpacing.s8,
        runSpacing: QeranSpacing.s8,
        children: [_keep(context), _delete(context)],
      ),
    );
  }

  Widget _keep(BuildContext context) => QeranButton(
    label:
        (reply
                ? LocaleKeys.community_keep_reply
                : LocaleKeys.community_keep_comment)
            .t(context),
    onPressed: onKeep,
    variant: QeranButtonVariant.secondary,
    size: QeranButtonSize.compact,
    leadingIcon: Icons.check_rounded,
    fullWidth: false,
  );

  Widget _delete(BuildContext context) => QeranButton(
    label: LocaleKeys.common_delete.t(context),
    onPressed: onDelete,
    variant: QeranButtonVariant.destructive,
    size: QeranButtonSize.compact,
    leadingIcon: Icons.delete_outline_rounded,
    fullWidth: false,
  );
}
