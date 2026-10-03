import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_own_text.dart';
import '../../../../../core/utils/relative_time.dart';
import '../../../domain/entities/community_comment.dart';
import '../community_author_avatar.dart';
import '../community_author_name.dart';
import 'comment_like_button.dart';

/// A comment or a reply (C1, C2, I2): who wrote it — a matchmaker with her
/// photo or ring and the «خطّابة» chip — how long ago (row form, Q6), the
/// text in its own direction and script (D13), and its Like. A reply sits
/// under its comment's text, its picture smaller.
class CommentRow extends StatelessWidget {
  const CommentRow({
    super.key,
    required this.comment,
    this.readOnly = false,
    this.onLike,
    this.menu,
  });

  final CommunityComment comment;

  /// A member who can read but not take part yet (D9): Like is dimmed.
  final bool readOnly;
  final VoidCallback? onLike;

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
          Expanded(
            child: _Body(comment, readOnly: readOnly, onLike: onLike),
          ),
          ?menu,
        ],
      ),
    );
  }
}

/// Name, chip and time; the text; the Like.
class _Body extends StatelessWidget {
  const _Body(this.comment, {required this.readOnly, this.onLike});

  final CommunityComment comment;
  final bool readOnly;
  final VoidCallback? onLike;

  @override
  Widget build(BuildContext context) {
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
        QeranOwnText(
          comment.text,
          style: QeranTypography.body.copyWith(color: QeranColors.inkStrong),
        ),
        CommentLikeButton(comment: comment, dimmed: readOnly, onTap: onLike),
      ],
    );
  }
}
