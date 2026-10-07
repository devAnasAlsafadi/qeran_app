import 'package:flutter/material.dart';
import 'package:qeran/features/community/domain/entities/community_comment.dart';
import 'package:qeran/features/community/domain/entities/community_flagged_item.dart';
import 'package:qeran/features/community/presentation/widgets/comments/comment_flag_panel.dart';
import 'package:qeran/features/community/presentation/widgets/community_author_avatar.dart';
import 'package:qeran/features/community/presentation/widgets/community_author_name.dart';

import '../../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../../core/design_system/tokens/qeran_shadows.dart';
import '../../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../../core/design_system/widgets/qeran_own_text.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../core/utils/relative_time.dart';
import '../../../../../../generated/locale_keys.g.dart';
import 'report_post_link.dart';

/// A row of «البلاغات» (E7): the flag line with when it was last reported
/// (Q10), who wrote the item and whether it's a comment or a reply, its
/// text in its own direction, «على: …» to the post at the item (D36), and
/// her Keep / Delete. [answering] while the server hasn't answered her.
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onKeep,
    required this.onDelete,
    this.answering = false,
  });

  final CommunityFlaggedItem item;
  final VoidCallback onOpen;
  final VoidCallback onKeep;
  final VoidCallback onDelete;
  final bool answering;

  @override
  Widget build(BuildContext context) {
    final time = QeranRelativeTime.ago(item.flag.lastReportedAt, context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: QeranColors.paper,
        borderRadius: QeranRadii.cardR,
        boxShadow: QeranShadows.e2,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: QeranSpacing.s16,
          vertical: QeranSpacing.s12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CommentFlagLine(
              flag: item.flag,
              trailing: time == null ? null : _Time(time),
            ),
            _ReportedItem(item.comment),
            ReportPostLink(snippet: item.postSnippet, onTap: onOpen),
            _answers(context),
          ],
        ),
      ),
    );
  }

  Widget _answers(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: QeranSpacing.s12),
    child: Row(
      children: [
        Expanded(
          child: QeranButton(
            label: LocaleKeys.matchmaker_community_report_keep.t(context),
            onPressed: answering ? null : onKeep,
            variant: QeranButtonVariant.secondary,
            size: QeranButtonSize.compact,
            leadingIcon: Icons.check_rounded,
          ),
        ),
        QeranSpacing.hs8,
        Expanded(
          child: QeranButton(
            label: LocaleKeys.common_delete.t(context),
            onPressed: answering ? null : onDelete,
            variant: QeranButtonVariant.destructive,
            size: QeranButtonSize.compact,
            leadingIcon: Icons.delete_outline_rounded,
          ),
        ),
      ],
    ),
  );
}

class _Time extends StatelessWidget {
  const _Time(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: QeranSpacing.s8),
    child: Text(
      text,
      style: QeranTypography.caption.copyWith(color: QeranColors.inkMuted),
    ),
  );
}

/// Who wrote it, «· تعليق» or «· رد», and its text in its own direction.
class _ReportedItem extends StatelessWidget {
  const _ReportedItem(this.comment);

  final CommunityComment comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommunityAuthorAvatar(author: comment.author, size: 36),
          QeranSpacing.hs12,
          Expanded(child: _texts(context)),
        ],
      ),
    );
  }

  Widget _texts(BuildContext context) {
    final kind = comment.isReply
        ? LocaleKeys.matchmaker_community_report_kind_reply
        : LocaleKeys.matchmaker_community_report_kind_comment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommunityAuthorName(
          author: comment.author,
          style: QeranTypography.label,
          trailing: Text(
            '· ${kind.t(context)}',
            style: QeranTypography.caption,
          ),
        ),
        const SizedBox(height: QeranSpacing.s2),
        QeranOwnText(
          comment.text,
          style: QeranTypography.body.copyWith(color: QeranColors.inkStrong),
        ),
      ],
    );
  }
}
