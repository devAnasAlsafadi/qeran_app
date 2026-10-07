import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_motion.dart';
import '../../../domain/entities/community_comment.dart';
import '../../../domain/entities/community_viewer.dart';
import '../../blocs/comments/comment_thread.dart';
import '../../blocs/comments/community_comments_cubit.dart';
import '../../blocs/composer/community_composer_cubit.dart';
import '../menus/community_comment_menu.dart';
import 'comment_row.dart';

/// A row, wired: its like to the comments, its Reply and retry to the
/// composer.
class CommunityCommentItem extends StatelessWidget {
  const CommunityCommentItem({
    super.key,
    required this.comment,
    required this.readOnly,
    required this.viewer,
    this.parent,
    this.delivery,
    this.highlighted = false,
  });

  final CommunityComment comment;
  final bool readOnly;
  final CommunityViewer viewer;

  /// The comment a reply answers.
  final CommunityComment? parent;
  final CommentDelivery? delivery;

  /// The row a landing is about (C8); it fades when that's over.
  final bool highlighted;

  static final Color _faded = QeranColors.gold12.withValues(alpha: 0);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: QeranMotion.gentle,
      color: highlighted ? QeranColors.gold12 : _faded,
      child: _row(context),
    );
  }

  Widget _row(BuildContext context) {
    final composer = context.read<CommunityComposerCubit>();
    final comments = context.read<CommunityCommentsCubit>();
    final answerable = !readOnly && !comment.isReply && delivery == null;
    return CommentRow(
      comment: comment,
      readOnly: readOnly,
      delivery: delivery,
      onLike: () => comments.toggleLike(comment.id, readOnly: readOnly),
      onReply: answerable ? () => composer.replyTo(comment) : null,
      onRetry: () => composer.retry(comment.id, comment.text, parent: parent),
      // Her answers to a report on it (E1–E6).
      onKeep: () => comments.keep(comment),
      onDelete: () => deleteCommunityComment(context, comment),
      // One on its way, or failed, has nothing to report or delete yet.
      menu: delivery == null
          ? communityCommentMenu(comment, viewer: viewer)
          : null,
    );
  }
}
