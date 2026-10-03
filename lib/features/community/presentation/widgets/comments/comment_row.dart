import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_own_text.dart';
import '../../../../../core/utils/relative_time.dart';
import '../../../domain/entities/community_comment.dart';
import '../community_author_avatar.dart';
import '../community_author_name.dart';
import '../../blocs/comments/comment_thread.dart';
import 'comment_actions.dart';
import 'comment_delivery_line.dart';

/// A comment or a reply (C1, C2, I2): who wrote it — a matchmaker with her
/// photo or ring and the «خطّابة» chip — how long ago (row form, Q6), the
/// text in its own direction and script (D13), and its Like and Reply. A
/// reply sits under its comment's text, its picture smaller. One the member
/// sent that isn't settled ([delivery]) is dimmed, with how it stands in
/// place of the actions (D5, D7).
class CommentRow extends StatelessWidget {
  const CommentRow({
    super.key,
    required this.comment,
    this.readOnly = false,
    this.delivery,
    this.onLike,
    this.onReply,
    this.onRetry,
    this.menu,
  });

  final CommunityComment comment;

  /// A member who can read but not take part yet (D9): Like is dimmed.
  final bool readOnly;

  /// On its way, or failed; null once posted.
  final CommentDelivery? delivery;
  final VoidCallback? onLike;

  /// Answer this comment; null where it can't be answered.
  final VoidCallback? onReply;

  /// Send a failed one again.
  final VoidCallback? onRetry;

  /// The ⋮ button, built from the server's flags.
  final Widget? menu;

  static const double avatarSize = 36;
  static const double replyAvatarSize = 28;

  /// Where a reply starts: in line with its comment's text.
  static const double replyIndent =
      QeranSpacing.s16 + avatarSize + QeranSpacing.s12;

  @override
  Widget build(BuildContext context) {
    final reply = comment.isReply;
    return Padding(
      // The ⋮ button brings its own 44 pt tap area to the end edge.
      padding: EdgeInsetsDirectional.only(
        start: reply ? replyIndent : QeranSpacing.s16,
        end: menu == null ? QeranSpacing.s16 : QeranSpacing.s2,
        top: QeranSpacing.s8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommunityAuthorAvatar(
            author: comment.author,
            size: reply ? replyAvatarSize : avatarSize,
          ),
          QeranSpacing.hs12,
          Expanded(child: _Body(this)),
          ?menu,
        ],
      ),
    );
  }
}

/// Name, chip and time; the text; the actions — or how it stands.
class _Body extends StatelessWidget {
  const _Body(this.row);

  final CommentRow row;

  @override
  Widget build(BuildContext context) {
    final comment = row.comment;
    final time = QeranRelativeTime.ago(
      comment.createdAt,
      context,
      compact: true,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CommunityAuthorName(
          author: comment.author,
          style: QeranTypography.label,
          trailing: time == null
              ? null
              : Text('· $time', style: QeranTypography.caption),
        ),
        const SizedBox(height: QeranSpacing.s2),
        Opacity(
          opacity: row.delivery == null ? 1 : 0.6,
          child: QeranOwnText(
            comment.text,
            style: QeranTypography.body.copyWith(color: QeranColors.inkStrong),
          ),
        ),
        _under(),
      ],
    );
  }

  /// The actions once posted; until then, how it stands.
  Widget _under() => switch (row.delivery) {
    final delivery? => CommentDeliveryLine(
      delivery: delivery,
      onRetry: row.onRetry ?? () {},
    ),
    null => CommentActions(
      comment: row.comment,
      dimmed: row.readOnly,
      onLike: row.onLike,
      onReply: row.onReply,
    ),
  };
}
